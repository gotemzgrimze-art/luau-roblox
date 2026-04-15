local TweenService = game:GetService("TweenService")

local MeteorEvent = {}

local function trackInstance(context, instance)
	table.insert(context.CreatedInstances, instance)
	return instance
end

local function getRootPart(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function MeteorEvent.Start(context)
	local alivePlayers = context.PlayerStateManager:GetAlivePlayers()
	if #alivePlayers == 0 then
		return
	end

	local targetPlayer = alivePlayers[context.Random:NextInteger(1, #alivePlayers)]
	local platformData = context.PlatformManager:GetAssignedPlatform(targetPlayer)

	if not platformData then
		return
	end

	local eventConfig = context.Config.Events.MeteorEvent
	local platformPart = platformData.Part

	context.Remotes.Announcement:FireAllClients(("Meteor targeting %s"):format(targetPlayer.Name))

	local warningPart = trackInstance(context, Instance.new("Part"))
	warningPart.Name = "MeteorWarning"
	warningPart.Anchored = true
	warningPart.CanCollide = false
	warningPart.Material = Enum.Material.Neon
	warningPart.Color = Color3.fromRGB(255, 170, 0)
	warningPart.Size = Vector3.new(platformPart.Size.X - 4, 0.3, platformPart.Size.Z - 4)
	warningPart.CFrame = platformPart.CFrame + Vector3.new(0, 1.25, 0)
	warningPart.Parent = workspace

	task.delay(eventConfig.WarningDuration, function()
		if not context.EventData.Active then
			return
		end

		local meteor = trackInstance(context, Instance.new("Part"))
		meteor.Name = "Meteor"
		meteor.Shape = Enum.PartType.Ball
		meteor.Anchored = true
		meteor.CanCollide = false
		meteor.Material = Enum.Material.Slate
		meteor.Color = Color3.fromRGB(126, 69, 41)
		meteor.Size = Vector3.new(10, 10, 10)
		meteor.Position = platformPart.Position + Vector3.new(0, eventConfig.MeteorHeight, 0)
		meteor.Parent = workspace

		local impactPosition = platformPart.Position + Vector3.new(0, 5, 0)
		local tween = TweenService:Create(
			meteor,
			TweenInfo.new(eventConfig.FallDuration, Enum.EasingStyle.Linear),
			{ Position = impactPosition }
		)
		tween:Play()

		task.delay(eventConfig.FallDuration, function()
			if not context.EventData.Active then
				return
			end

			local blast = trackInstance(context, Instance.new("Part"))
			blast.Name = "MeteorImpact"
			blast.Shape = Enum.PartType.Ball
			blast.Anchored = true
			blast.CanCollide = false
			blast.Material = Enum.Material.Neon
			blast.Color = Color3.fromRGB(255, 110, 70)
			blast.Transparency = 0.35
			blast.Size = Vector3.new(eventConfig.ImpactRadius * 2, eventConfig.ImpactRadius * 2, eventConfig.ImpactRadius * 2)
			blast.Position = platformPart.Position + Vector3.new(0, 5, 0)
			blast.Parent = workspace

			for _, player in ipairs(context.PlayerStateManager:GetAlivePlayers()) do
				local rootPart = getRootPart(player)
				if rootPart then
					local distance = (rootPart.Position - blast.Position).Magnitude
					if distance <= eventConfig.ImpactRadius then
						context.PlayerStateManager:DamagePlayer(player, eventConfig.Damage, "Meteor")
					end
				end
			end

			task.delay(0.35, function()
				if meteor.Parent then
					meteor:Destroy()
				end
				if blast.Parent then
					blast:Destroy()
				end
			end)
		end)
	end)
end

function MeteorEvent.Cleanup(context)
	context.EventData.Active = false
end

return MeteorEvent
