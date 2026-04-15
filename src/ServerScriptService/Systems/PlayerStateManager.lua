local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerStateManager = {}
PlayerStateManager.__index = PlayerStateManager

function PlayerStateManager.new(config, remotes)
	local self = setmetatable({}, PlayerStateManager)

	self.Config = config
	self.Remotes = remotes
	self.States = {}
	self.DamageEnabled = false
	self.PlayerDied = Instance.new("BindableEvent")

	self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
		self:_registerPlayer(player)
	end)

	self.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		self:_unregisterPlayer(player)
	end)

	self.HeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self:_onHeartbeat(deltaTime)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_registerPlayer(player)
	end

	return self
end

function PlayerStateManager:_createState()
	return {
		IsInRound = false,
		IsAlive = false,
		CurrentHealth = self.Config.Health.Max,
		LastDamageAt = 0,
		RegenAccumulator = 0,
		Character = nil,
		Humanoid = nil,
		RootPart = nil,
		PlayerConnections = {},
		CharacterConnections = {},
	}
end

function PlayerStateManager:_disconnectConnections(connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	table.clear(connections)
end

function PlayerStateManager:_registerPlayer(player)
	local state = self:_createState()
	self.States[player] = state

	table.insert(state.PlayerConnections, player.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(player, character)
	end))

	table.insert(state.PlayerConnections, player.CharacterRemoving:Connect(function(character)
		self:_onCharacterRemoving(player, character)
	end))

	if player.Character then
		task.spawn(function()
			self:_onCharacterAdded(player, player.Character)
		end)
	end
end

function PlayerStateManager:_unregisterPlayer(player)
	local state = self.States[player]
	if not state then
		return
	end

	self:_disconnectConnections(state.PlayerConnections)
	self:_disconnectConnections(state.CharacterConnections)
	self.States[player] = nil
end

function PlayerStateManager:_onCharacterAdded(player, character)
	local state = self.States[player]
	if not state then
		return
	end

	self:_disconnectConnections(state.CharacterConnections)
	state.Character = character
	state.Humanoid = character:WaitForChild("Humanoid", 10)
	state.RootPart = character:WaitForChild("HumanoidRootPart", 10)

	if state.Humanoid then
		state.Humanoid.MaxHealth = self.Config.Health.Max
		state.Humanoid.BreakJointsOnDeath = false

		if state.IsAlive then
			state.Humanoid.Health = math.max(state.CurrentHealth, 1)
		else
			state.Humanoid.Health = self.Config.Health.Max
		end

		table.insert(state.CharacterConnections, state.Humanoid.Died:Connect(function()
			if state.IsInRound and state.IsAlive then
				self:EliminatePlayer(player, "Health depleted")
			end
		end))
	end

	self:_sendHealthUpdate(player)
end

function PlayerStateManager:_onCharacterRemoving(player, character)
	local state = self.States[player]
	if not state or state.Character ~= character then
		return
	end

	self:_disconnectConnections(state.CharacterConnections)
	state.Character = nil
	state.Humanoid = nil
	state.RootPart = nil
end

function PlayerStateManager:_waitForCharacterReady(player)
	local state = self.States[player]
	local timeoutAt = os.clock() + 10

	while state and os.clock() < timeoutAt do
		if state.Character and state.Humanoid and state.RootPart then
			return true
		end

		task.wait()
		state = self.States[player]
	end

	return false
end

function PlayerStateManager:_sendHealthUpdate(player)
	local state = self.States[player]
	if not state then
		return
	end

	self.Remotes.HealthUpdate:FireClient(player, {
		Health = math.max(0, math.floor(state.CurrentHealth + 0.5)),
		MaxHealth = self.Config.Health.Max,
		IsAlive = state.IsAlive,
	})
end

function PlayerStateManager:_setHealth(player, newHealth)
	local state = self.States[player]
	if not state then
		return
	end

	state.CurrentHealth = math.clamp(newHealth, 0, self.Config.Health.Max)

	if state.Humanoid then
		state.Humanoid.MaxHealth = self.Config.Health.Max
		if state.CurrentHealth > 0 then
			state.Humanoid.Health = state.CurrentHealth
		else
			state.Humanoid.Health = 0
		end
	end

	self:_sendHealthUpdate(player)
end

function PlayerStateManager:_onHeartbeat(deltaTime)
	for player, state in pairs(self.States) do
		if state.IsInRound and state.IsAlive then
			local rootPart = state.RootPart

			if rootPart and rootPart.Position.Y < self.Config.World.FallDeathY then
				self:EliminatePlayer(player, "Fell")
				continue
			end

			if state.CurrentHealth < self.Config.Health.Max then
				local canRegen = (os.clock() - state.LastDamageAt) >= self.Config.Health.RegenDelay
				if canRegen then
					state.RegenAccumulator += deltaTime

					if state.RegenAccumulator >= self.Config.Health.RegenTick then
						local ticks = math.floor(state.RegenAccumulator / self.Config.Health.RegenTick)
						state.RegenAccumulator -= ticks * self.Config.Health.RegenTick

						local regenAmount = ticks * self.Config.Health.RegenPerSecond * self.Config.Health.RegenTick
						self:_setHealth(player, state.CurrentHealth + regenAmount)
					end
				end
			end
		end
	end
end

function PlayerStateManager:SetDamageEnabled(isEnabled)
	self.DamageEnabled = isEnabled
end

function PlayerStateManager:LoadPlayerCharacter(player)
	player:LoadCharacter()
	self:_waitForCharacterReady(player)
end

function PlayerStateManager:PreparePlayersForRound(players)
	for _, player in ipairs(players) do
		local state = self.States[player]
		if state then
			state.IsInRound = true
			state.IsAlive = true
			state.CurrentHealth = self.Config.Health.Max
			state.LastDamageAt = 0
			state.RegenAccumulator = 0

			self:LoadPlayerCharacter(player)
			self:_setHealth(player, self.Config.Health.Max)
		end
	end
end

function PlayerStateManager:ResetPlayersAfterRound(players)
	self.DamageEnabled = false

	for _, player in ipairs(players) do
		local state = self.States[player]
		if state then
			state.IsInRound = false
			state.IsAlive = false
			state.CurrentHealth = self.Config.Health.Max
			state.LastDamageAt = 0
			state.RegenAccumulator = 0

			self:_sendHealthUpdate(player)
		end
	end
end

function PlayerStateManager:GetAlivePlayers()
	local alivePlayers = {}

	for player, state in pairs(self.States) do
		if state.IsInRound and state.IsAlive and player.Parent == Players then
			table.insert(alivePlayers, player)
		end
	end

	table.sort(alivePlayers, function(left, right)
		return left.UserId < right.UserId
	end)

	return alivePlayers
end

function PlayerStateManager:GetAliveCount()
	return #self:GetAlivePlayers()
end

function PlayerStateManager:IsPlayerAlive(player)
	local state = self.States[player]
	return state ~= nil and state.IsInRound and state.IsAlive
end

function PlayerStateManager:DamagePlayer(player, amount, reason, bypassProtection)
	local state = self.States[player]
	if not state or not state.IsInRound or not state.IsAlive then
		return false
	end

	if not bypassProtection and not self.DamageEnabled then
		return false
	end

	if amount <= 0 then
		return false
	end

	state.LastDamageAt = os.clock()
	state.RegenAccumulator = 0

	local resultingHealth = math.max(0, state.CurrentHealth - amount)
	self:_setHealth(player, resultingHealth)

	if resultingHealth <= 0 then
		self:EliminatePlayer(player, reason)
	end

	return true
end

function PlayerStateManager:EliminatePlayer(player, reason)
	local state = self.States[player]
	if not state or not state.IsInRound or not state.IsAlive then
		return false
	end

	state.IsAlive = false
	state.CurrentHealth = 0
	state.LastDamageAt = os.clock()
	state.RegenAccumulator = 0

	if state.Humanoid then
		state.Humanoid.Health = 0
	end

	self:_sendHealthUpdate(player)
	self.PlayerDied:Fire(player, reason or "Eliminated")

	return true
end

function PlayerStateManager:GetDeathSignal()
	return self.PlayerDied.Event
end

return PlayerStateManager
