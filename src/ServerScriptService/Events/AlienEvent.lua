local AlienEvent = {}

local function trackInstance(context, instance)
	table.insert(context.CreatedInstances, instance)
	return instance
end

function AlienEvent.Start(context)
	local platformData = context.PlatformManager:GetRandomEnabledPlatform(context.Random)
	if not platformData then
		return
	end

	local eventConfig = context.Config.Events.AlienEvent
	local platformPart = platformData.Part

	context.Remotes.Announcement:FireAllClients(("Alien beam on platform %d"):format(platformData.Index))

	local beam = trackInstance(context, Instance.new("Part"))
	beam.Name = "AlienWarning"
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(110, 255, 140)
	beam.Size = Vector3.new(4, 40, 4)
	beam.CFrame = platformPart.CFrame + Vector3.new(0, 20, 0)
	beam.Parent = workspace

	task.delay(eventConfig.WarningDuration, function()
		if not context.EventData.Active then
			return
		end

		context.EventData.DisabledPlatform = platformData
		context.PlatformManager:SetPlatformEnabled(platformData, false)

		local playersOnPlatform = context.PlatformManager:GetPlayersStandingOnPlatform(
			platformData,
			context.PlayerStateManager:GetAlivePlayers()
		)

		for _, player in ipairs(playersOnPlatform) do
			context.PlayerStateManager:EliminatePlayer(player, "Alien collapse")
		end

		local collapseDuration = math.max(
			eventConfig.MinimumCollapseDuration,
			context.Duration - eventConfig.WarningDuration
		)

		task.delay(collapseDuration, function()
			if context.EventData.Active then
				context.PlatformManager:SetPlatformEnabled(platformData, true)
				context.EventData.DisabledPlatform = nil
			end
		end)
	end)
end

function AlienEvent.Cleanup(context)
	context.EventData.Active = false

	local disabledPlatform = context.EventData.DisabledPlatform
	if disabledPlatform then
		context.PlatformManager:SetPlatformEnabled(disabledPlatform, true)
	end
end

return AlienEvent
