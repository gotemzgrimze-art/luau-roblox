local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local Remotes = require(ReplicatedStorage.Modules.RemoteDefinitions)

local EventManager = require(script.Parent.EventManager)
local PlatformManager = require(script.Parent.PlatformManager)
local PlayerStateManager = require(script.Parent.PlayerStateManager)

local RoundManager = {}
RoundManager.__index = RoundManager

local singleton = nil

function RoundManager.new()
	local self = setmetatable({}, RoundManager)

	self.Config = Config
	self.Remotes = Remotes
	self.PlatformManager = PlatformManager.new(Config)
	self.PlayerStateManager = PlayerStateManager.new(Config, Remotes)
	self.EventManager = EventManager.new(Config, Remotes, self.PlatformManager, self.PlayerStateManager, self)
	self.IsRoundActive = false

	self.PlayerStateManager:GetDeathSignal():Connect(function(player, reason)
		self:_onPlayerEliminated(player, reason)
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:_sendPlayerToLobby(player)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_sendPlayerToLobby(player)
		end)
	end

	return self
end

function RoundManager:_broadcastRoundState(phase, message, timeLeft)
	self.Remotes.RoundState:FireAllClients({
		Phase = phase,
		Message = message,
		TimeLeft = timeLeft,
		AliveCount = self.PlayerStateManager:GetAliveCount(),
		MaxPlayers = self.Config.MaxPlayers,
	})
end

function RoundManager:_announce(message)
	self.Remotes.Announcement:FireAllClients(message)
end

function RoundManager:_sendPlayerToLobby(player)
	if not player.Parent then
		return
	end

	if self.IsRoundActive and self.PlayerStateManager:IsPlayerAlive(player) then
		return
	end

	self.PlayerStateManager:LoadPlayerCharacter(player)
	self.PlatformManager:TeleportPlayerToLobby(player)
end

function RoundManager:_getParticipants()
	local allPlayers = Players:GetPlayers()
	local participants = {}

	for index = 1, math.min(#allPlayers, self.Config.MaxPlayers) do
		table.insert(participants, allPlayers[index])
	end

	return participants
end

function RoundManager:_getInterEventDelay(aliveCount)
	local eliminatedCount = self.Config.MaxPlayers - aliveCount
	local delay = self.Config.Round.EventDelayBase - (eliminatedCount * self.Config.Round.EventDelayStep)

	return math.max(self.Config.Round.EventDelayMin, delay)
end

function RoundManager:_waitSeconds(seconds, phase, messageBuilder, abortCondition)
	local deadline = os.clock() + seconds

	while true do
		if abortCondition and abortCondition() then
			return false
		end

		local remaining = math.max(0, deadline - os.clock())
		if remaining <= 0 then
			break
		end

		local rounded = math.ceil(remaining)
		local message = messageBuilder and messageBuilder(rounded) or nil
		self:_broadcastRoundState(phase, message, rounded)
		task.wait(1)
	end

	return true
end

function RoundManager:_waitForEnoughPlayers()
	while true do
		local playerCount = #Players:GetPlayers()
		self:_broadcastRoundState("Lobby", ("Waiting for players (%d/%d)"):format(playerCount, self.Config.MinPlayersToStart), nil)

		if playerCount >= self.Config.MinPlayersToStart then
			return
		end

		task.wait(self.Config.Round.LobbyPollInterval)
	end
end

function RoundManager:_onPlayerEliminated(player, reason)
	if not self.IsRoundActive then
		return
	end

	self:_announce(("%s was eliminated (%s)"):format(player.Name, reason))
end

function RoundManager:_resolveWinner()
	local alivePlayers = self.PlayerStateManager:GetAlivePlayers()

	if #alivePlayers == 1 then
		return alivePlayers[1]
	end

	return nil
end

function RoundManager:_runRound(participants)
	self.IsRoundActive = true
	self.PlatformManager:ResetRound()
	self.PlayerStateManager:PreparePlayersForRound(participants)
	self.PlatformManager:AssignPlayers(participants)
	self.PlayerStateManager:SetDamageEnabled(false)
	self.PlayerStateManager:SetPvpEnabled(false)

	self:_announce("Round starting")

	self:_waitSeconds(
		self.Config.Round.RoundStartCountdown,
		"RoundStart",
		function(remaining)
			return ("Round begins in %d"):format(remaining)
		end
	)

	if self.PlayerStateManager:GetAliveCount() <= 1 then
		return
	end

	self:_announce("Grace period")

	self:_waitSeconds(
		self.Config.Round.GracePeriod,
		"Grace",
		function(remaining)
			return ("Grace period: %d"):format(remaining)
		end,
		function()
			return self.PlayerStateManager:GetAliveCount() <= 1
		end
	)

	if self.PlayerStateManager:GetAliveCount() <= 1 then
		return
	end

	self.PlayerStateManager:SetDamageEnabled(true)

	while self.PlayerStateManager:GetAliveCount() > 1 do
		local eventName, eventDuration = self.EventManager:StartRandomEvent()
		if not eventName then
			break
		end

		self:_waitSeconds(
			eventDuration,
			"Event",
			function(remaining)
				return ("%s active: %d"):format(eventName, remaining)
			end,
			function()
				return self.PlayerStateManager:GetAliveCount() <= 1
			end
		)

		self.EventManager:CleanupActiveEvent()

		if self.PlayerStateManager:GetAliveCount() <= 1 then
			break
		end

		local aliveCount = self.PlayerStateManager:GetAliveCount()
		local delayBetweenEvents = self:_getInterEventDelay(aliveCount)

		self:_waitSeconds(
			delayBetweenEvents,
			"Intermission",
			function(remaining)
				return ("Next event in %d"):format(remaining)
			end,
			function()
				return self.PlayerStateManager:GetAliveCount() <= 1
			end
		)
	end
end

function RoundManager:_finishRound(participants)
	self.PlayerStateManager:SetDamageEnabled(false)
	self.PlayerStateManager:SetPvpEnabled(false)
	self.EventManager:CleanupActiveEvent()

	local winner = self:_resolveWinner()
	if winner then
		self:_announce(("%s wins the round"):format(winner.Name))
	else
		self:_announce("No winner this round")
	end

	self:_waitSeconds(
		self.Config.Round.EndRoundDelay,
		"RoundEnd",
		function(remaining)
			if winner then
				return ("Winner: %s (%d)"):format(winner.Name, remaining)
			end

			return ("Resetting to lobby (%d)"):format(remaining)
		end
	)

	self.PlayerStateManager:ResetPlayersAfterRound(participants)
	self.PlatformManager:ResetRound()

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_sendPlayerToLobby(player)
		end)
	end

	self.IsRoundActive = false
end

function RoundManager:_runLoop()
	while true do
		self:_waitForEnoughPlayers()

		local participants = self:_getParticipants()
		if #participants >= self.Config.MinPlayersToStart then
			self:_runRound(participants)
			self:_finishRound(participants)
		end
	end
end

function RoundManager.Start()
	if singleton then
		return singleton
	end

	singleton = RoundManager.new()
	task.spawn(function()
		singleton:_runLoop()
	end)

	return singleton
end

return RoundManager
