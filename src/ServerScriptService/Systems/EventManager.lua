local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EventManager = {}
EventManager.__index = EventManager

local REGISTERED_EVENTS = {
	require(script.Parent.Parent.Events.TralaleloTralalaTsunamiEvent),
	require(script.Parent.Parent.Events.BombordiroCrocodileBombEvent),
	require(script.Parent.Parent.Events.LiriliLariraFreezeEvent),
	require(script.Parent.Parent.Events.BrrBrrPatatimHighJumpEvent),
	require(script.Parent.Parent.Events.MeowlLowGravityEvent),
	require(script.Parent.Parent.Events.SlapFightEvent),
	require(script.Parent.Parent.Events.RocketLauncherMadnessEvent),
	require(script.Parent.Parent.Events.SwordDuelEvent),
}

local function safeDestroy(instance)
	if instance then
		instance:Destroy()
	end
end

function EventManager.new(config, remotes, platformManager, playerStateManager, roundManager)
	local self = setmetatable({}, EventManager)

	self.Config = config
	self.Remotes = remotes
	self.PlatformManager = platformManager
	self.PlayerStateManager = playerStateManager
	self.RoundManager = roundManager
	self.Random = Random.new()
	self.EventModules = {}
	self.EventLookup = {}
	self.ActiveEventName = nil
	self.ActiveEventModule = nil
	self.ActiveContext = nil
	self.LastEventName = nil

	for _, eventModule in ipairs(REGISTERED_EVENTS) do
		self:RegisterEvent(eventModule)
	end

	return self
end

function EventManager:RegisterEvent(eventModule)
	if type(eventModule) ~= "table" then
		error("Event module must return a table")
	end

	if type(eventModule.Name) ~= "string" then
		error("Event module is missing Name")
	end

	if type(eventModule.CanRun) ~= "function" or type(eventModule.Start) ~= "function" or type(eventModule.Cleanup) ~= "function" then
		error(("Event module %s is missing required functions"):format(eventModule.Name))
	end

	table.insert(self.EventModules, eventModule)
	self.EventLookup[eventModule.Name] = eventModule
end

function EventManager:_resolveEventSettings(eventModule)
	local eventConfig = self.Config.Events[eventModule.Name] or {}
	local weight = eventConfig.Weight or eventModule.Weight or 1
	local duration = eventConfig.Duration or eventModule.Duration or 5

	return eventConfig, weight, duration
end

function EventManager:_buildPlatformMapping(players)
	return self.PlatformManager:GetAssignedPlatformMapping(players)
end

function EventManager:_createContext(eventModule, duration, isPreview)
	local eventConfig = self.Config.Events[eventModule.Name] or {}
	local alivePlayers = self.PlayerStateManager:GetAlivePlayers()

	local context = {
		Name = eventModule.Name,
		EventModule = eventModule,
		EventConfig = eventConfig,
		Config = self.Config,
		Remotes = self.Remotes,
		RoundManager = self.RoundManager,
		PlayerStateManager = self.PlayerStateManager,
		PlatformManager = self.PlatformManager,
		EventManager = self,
		Random = self.Random,
		Duration = duration,
		Preview = isPreview == true,
		AlivePlayers = alivePlayers,
		PlatformMapping = self:_buildPlatformMapping(alivePlayers),
		CreatedInstances = {},
		Connections = {},
		CleanupCallbacks = {},
		State = {},
		EventData = {
			Active = isPreview ~= true,
		},
	}

	function context:IsActive()
		return not self.Preview and self.EventData.Active and self.EventManager.ActiveContext == self
	end

	function context:RefreshAlivePlayers()
		self.AlivePlayers = self.PlayerStateManager:GetAlivePlayers()
		return self.AlivePlayers
	end

	function context:GetAlivePlayers()
		return self:RefreshAlivePlayers()
	end

	function context:GetAliveCount()
		return #self:GetAlivePlayers()
	end

	function context:IsPlayerAlive(player)
		return self.PlayerStateManager:IsPlayerAlive(player)
	end

	function context:RefreshPlatformMapping()
		self.PlatformMapping = self.EventManager:_buildPlatformMapping(self:GetAlivePlayers())
		return self.PlatformMapping
	end

	function context:GetPlayerPlatform(player)
		return self.PlatformManager:GetAssignedPlatform(player)
	end

	function context:GetPlatformsInRow(rowIndex)
		return self.PlatformManager:GetPlatformsInRow(rowIndex)
	end

	function context:GetPlayersStandingOnPlatform(platformData)
		return self.PlatformManager:GetPlayersStandingOnPlatform(platformData, self:GetAlivePlayers())
	end

	function context:GetPlayersStandingOnRow(rowIndex)
		local playersOnRow = {}
		local seen = {}

		for _, platformData in ipairs(self:GetPlatformsInRow(rowIndex)) do
			for _, player in ipairs(self:GetPlayersStandingOnPlatform(platformData)) do
				if not seen[player] then
					seen[player] = true
					table.insert(playersOnRow, player)
				end
			end
		end

		return playersOnRow
	end

	function context:GetRandomAlivePlayer()
		local currentAlivePlayers = self:GetAlivePlayers()
		if #currentAlivePlayers == 0 then
			return nil
		end

		local index = self.Random:NextInteger(1, #currentAlivePlayers)
		return currentAlivePlayers[index]
	end

	function context:GetCharacter(player)
		return self.PlayerStateManager:GetCharacter(player)
	end

	function context:GetHumanoid(player)
		return self.PlayerStateManager:GetHumanoid(player)
	end

	function context:GetRootPart(player)
		return self.PlayerStateManager:GetRootPart(player)
	end

	function context:Announce(message)
		self.Remotes.Announcement:FireAllClients(message)
	end

	function context:TrackInstance(instance)
		table.insert(self.CreatedInstances, instance)
		return instance
	end

	function context:TrackConnection(connection)
		table.insert(self.Connections, connection)
		return connection
	end

	function context:TrackCleanup(callback)
		table.insert(self.CleanupCallbacks, callback)
		return callback
	end

	function context:Schedule(delaySeconds, callback)
		task.delay(delaySeconds, function()
			if self:IsActive() then
				callback()
			end
		end)
	end

	function context:DamagePlayer(player, amount, reason, bypassProtection)
		return self.PlayerStateManager:DamagePlayer(player, amount, reason, bypassProtection)
	end

	function context:DamagePlayerFromPlayer(attacker, target, amount, reason)
		return self.PlayerStateManager:DamagePlayerFromPlayer(attacker, target, amount, reason)
	end

	function context:EnablePvp()
		if self.State.PvpEnabled then
			return
		end

		self.State.PvpEnabled = true
		self.PlayerStateManager:SetPvpEnabled(true)

		self:TrackCleanup(function()
			self.PlayerStateManager:SetPvpEnabled(false)
		end)
	end

	function context:ApplyKnockback(player, velocity)
		local rootPart = self:GetRootPart(player)
		if rootPart then
			rootPart.AssemblyLinearVelocity += velocity
		end
	end

	function context:GetPlayersInBox(cframe, size, excludedPlayers)
		local results = {}
		local seen = {}
		local excluded = {}

		if excludedPlayers then
			for _, player in ipairs(excludedPlayers) do
				excluded[player] = true
			end
		end

		for _, part in ipairs(Workspace:GetPartBoundsInBox(cframe, size)) do
			local character = part:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)

			if player and not seen[player] and not excluded[player] and self:IsPlayerAlive(player) then
				seen[player] = true
				table.insert(results, player)
			end
		end

		return results
	end

	function context:GetPlayersInRadius(position, radius, excludedPlayers)
		local results = {}
		local excluded = {}

		if excludedPlayers then
			for _, player in ipairs(excludedPlayers) do
				excluded[player] = true
			end
		end

		for _, player in ipairs(self:GetAlivePlayers()) do
			if not excluded[player] then
				local rootPart = self:GetRootPart(player)
				if rootPart and (rootPart.Position - position).Magnitude <= radius then
					table.insert(results, player)
				end
			end
		end

		return results
	end

	function context:GrantTemporaryTool(player, tool)
		tool.CanBeDropped = false
		tool:SetAttribute("EventTemporaryTool", true)
		self:TrackInstance(tool)

		local backpack = player:FindFirstChildOfClass("Backpack")
		local character = self:GetCharacter(player)

		if backpack then
			tool.Parent = backpack
		elseif character then
			tool.Parent = character
		else
			tool.Parent = player
		end

		return tool
	end

	function context:ApplyHumanoidOverrides(players, overrides)
		local trackedHumanoids = {}
		local restored = false

		for _, player in ipairs(players) do
			local humanoid = self:GetHumanoid(player)
			if humanoid then
				local original = {}

				for propertyName, overrideValue in pairs(overrides) do
					original[propertyName] = humanoid[propertyName]
					humanoid[propertyName] = overrideValue
				end

				table.insert(trackedHumanoids, {
					Humanoid = humanoid,
					Original = original,
				})
			end
		end

		local function restore()
			if restored then
				return
			end

			restored = true

			for _, entry in ipairs(trackedHumanoids) do
				local humanoid = entry.Humanoid
				if humanoid and humanoid.Parent then
					for propertyName, originalValue in pairs(entry.Original) do
						humanoid[propertyName] = originalValue
					end
				end
			end
		end

		self:TrackCleanup(restore)
		return restore
	end

	function context:ApplyHumanoidOverridesPerPlayer(players, buildOverrides)
		local trackedHumanoids = {}
		local restored = false

		for _, player in ipairs(players) do
			local humanoid = self:GetHumanoid(player)
			if humanoid then
				local overrides = buildOverrides(player, humanoid)
				if overrides and next(overrides) ~= nil then
					local original = {}

					for propertyName, overrideValue in pairs(overrides) do
						original[propertyName] = humanoid[propertyName]
						humanoid[propertyName] = overrideValue
					end

					table.insert(trackedHumanoids, {
						Humanoid = humanoid,
						Original = original,
					})
				end
			end
		end

		local function restore()
			if restored then
				return
			end

			restored = true

			for _, entry in ipairs(trackedHumanoids) do
				local humanoid = entry.Humanoid
				if humanoid and humanoid.Parent then
					for propertyName, originalValue in pairs(entry.Original) do
						humanoid[propertyName] = originalValue
					end
				end
			end
		end

		self:TrackCleanup(restore)
		return restore
	end

	return context
end

function EventManager:_buildValidCandidates()
	local candidates = {}

	for _, eventModule in ipairs(self.EventModules) do
		local _, weight, duration = self:_resolveEventSettings(eventModule)
		if weight > 0 then
			local previewContext = self:_createContext(eventModule, duration, true)
			local success, canRun = pcall(eventModule.CanRun, previewContext)

			if success and canRun then
				table.insert(candidates, {
					Module = eventModule,
					Weight = weight,
					Duration = duration,
				})
			end
		end
	end

	if self.Config.Events.Selection.AvoidImmediateRepeat and #candidates > 1 and self.LastEventName then
		local filteredCandidates = {}

		for _, candidate in ipairs(candidates) do
			if candidate.Module.Name ~= self.LastEventName then
				table.insert(filteredCandidates, candidate)
			end
		end

		if #filteredCandidates > 0 then
			candidates = filteredCandidates
		end
	end

	return candidates
end

function EventManager:_chooseWeightedCandidate(candidates)
	local totalWeight = 0

	for _, candidate in ipairs(candidates) do
		totalWeight += candidate.Weight
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = self.Random:NextNumber(0, totalWeight)
	local runningWeight = 0

	for _, candidate in ipairs(candidates) do
		runningWeight += candidate.Weight
		if roll <= runningWeight then
			return candidate
		end
	end

	return candidates[#candidates]
end

function EventManager:StartRandomEvent()
	if self.ActiveContext then
		self:CleanupActiveEvent()
	end

	local candidates = self:_buildValidCandidates()
	if #candidates == 0 then
		return nil, 0
	end

	local chosenCandidate = self:_chooseWeightedCandidate(candidates)
	if not chosenCandidate then
		return nil, 0
	end

	local eventModule = chosenCandidate.Module
	local context = self:_createContext(eventModule, chosenCandidate.Duration, false)

	self.ActiveEventName = eventModule.Name
	self.ActiveEventModule = eventModule
	self.ActiveContext = context
	self.LastEventName = eventModule.Name

	local success, startError = pcall(eventModule.Start, context)
	if not success then
		warn(("Event %s failed to start: %s"):format(eventModule.Name, startError))
		self:CleanupActiveEvent()
		return nil, 0
	end

	return eventModule.Name, context.Duration
end

function EventManager:IsEventActive()
	return self.ActiveContext ~= nil
end

function EventManager:CleanupActiveEvent()
	local context = self.ActiveContext
	local eventModule = self.ActiveEventModule

	if not context or not eventModule then
		return
	end

	context.EventData.Active = false

	local cleanupSuccess, cleanupError = pcall(eventModule.Cleanup, context)
	if not cleanupSuccess then
		warn(("Event %s cleanup failed: %s"):format(eventModule.Name, cleanupError))
	end

	for index = #context.CleanupCallbacks, 1, -1 do
		local success, callbackError = pcall(context.CleanupCallbacks[index])
		if not success then
			warn(("Event %s cleanup callback failed: %s"):format(eventModule.Name, callbackError))
		end
	end

	for _, connection in ipairs(context.Connections) do
		connection:Disconnect()
	end

	for _, instance in ipairs(context.CreatedInstances) do
		safeDestroy(instance)
	end

	self.PlayerStateManager:SetPvpEnabled(false)
	self.ActiveEventName = nil
	self.ActiveEventModule = nil
	self.ActiveContext = nil
end

return EventManager
