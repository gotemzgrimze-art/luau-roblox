local EventManager = {}
EventManager.__index = EventManager

function EventManager.new(config, remotes, platformManager, playerStateManager)
	local self = setmetatable({}, EventManager)

	self.Config = config
	self.Remotes = remotes
	self.PlatformManager = platformManager
	self.PlayerStateManager = playerStateManager
	self.Random = Random.new()

	self.EventModules = {
		MeteorEvent = require(script.Parent.Parent.Events.MeteorEvent),
		FireEvent = require(script.Parent.Parent.Events.FireEvent),
		AlienEvent = require(script.Parent.Parent.Events.AlienEvent),
	}

	self.EventNames = { "MeteorEvent", "FireEvent", "AlienEvent" }
	self.ActiveEventName = nil
	self.ActiveEventModule = nil
	self.ActiveContext = nil

	return self
end

function EventManager:_destroyTrackedResources(context)
	for _, connection in ipairs(context.Connections) do
		connection:Disconnect()
	end

	for _, instance in ipairs(context.CreatedInstances) do
		if instance and instance.Parent then
			instance:Destroy()
		end
	end

	table.clear(context.Connections)
	table.clear(context.CreatedInstances)
end

function EventManager:GetScaledEventDuration(aliveCount)
	local eliminatedCount = self.Config.MaxPlayers - aliveCount
	local duration = self.Config.Round.EventDurationBase - (eliminatedCount * self.Config.Round.EventDurationStep)

	return math.max(self.Config.Round.EventDurationMin, duration)
end

function EventManager:StartRandomEvent()
	if self.ActiveContext then
		self:CleanupActiveEvent()
	end

	local alivePlayers = self.PlayerStateManager:GetAlivePlayers()
	if #alivePlayers <= 1 then
		return nil, 0
	end

	local eventName = self.EventNames[self.Random:NextInteger(1, #self.EventNames)]
	local eventModule = self.EventModules[eventName]
	local duration = self:GetScaledEventDuration(#alivePlayers)

	local context = {
		Name = eventName,
		Config = self.Config,
		Remotes = self.Remotes,
		Random = self.Random,
		Duration = duration,
		CreatedInstances = {},
		Connections = {},
		EventData = {
			Active = true,
		},
		PlatformManager = self.PlatformManager,
		PlayerStateManager = self.PlayerStateManager,
		AlivePlayers = alivePlayers,
	}

	self.ActiveEventName = eventName
	self.ActiveEventModule = eventModule
	self.ActiveContext = context

	eventModule.Start(context)

	return eventName, duration
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
	eventModule.Cleanup(context)
	self:_destroyTrackedResources(context)

	self.ActiveEventName = nil
	self.ActiveEventModule = nil
	self.ActiveContext = nil
end

return EventManager
