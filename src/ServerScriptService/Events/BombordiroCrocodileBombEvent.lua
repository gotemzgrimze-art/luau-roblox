local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BombordiroCrocodileBombEvent = {
	Name = "BombordiroCrocodileBombEvent",
	Weight = 10,
	Duration = 5,
}

function BombordiroCrocodileBombEvent.CanRun(context)
	for _, player in ipairs(context:GetAlivePlayers()) do
		if context:GetPlayerPlatform(player) then
			return true
		end
	end

	return false
end

function BombordiroCrocodileBombEvent.Start(context)
	local eventConfig = context.EventConfig
	local targetCandidates = {}

	for _, player in ipairs(context:GetAlivePlayers()) do
		if context:GetPlayerPlatform(player) then
			table.insert(targetCandidates, player)
		end
	end

	if #targetCandidates == 0 then
		return
	end

	local targetPlayer = targetCandidates[context.Random:NextInteger(1, #targetCandidates)]
	local platformData = context:GetPlayerPlatform(targetPlayer)
	if not platformData then
		return
	end

	local platformPart = platformData.Part

	context:Announce(("Bombordiro Crocodile bomb incoming on %s"):format(targetPlayer.Name))

	local warningMarker = context:TrackInstance(Instance.new("Part"))
	warningMarker.Name = "BombWarning"
	warningMarker.Shape = Enum.PartType.Cylinder
	warningMarker.Anchored = true
	warningMarker.CanCollide = false
	warningMarker.Material = Enum.Material.Neon
	warningMarker.Color = Color3.fromRGB(255, 215, 70)
	warningMarker.Size = Vector3.new(0.35, platformPart.Size.X - 4, platformPart.Size.Z - 4)
	warningMarker.CFrame = platformPart.CFrame * CFrame.Angles(0, 0, math.rad(90)) + Vector3.new(0, 1.5, 0)
	warningMarker.Parent = Workspace

	context:Schedule(eventConfig.WarningDuration, function()
		if warningMarker.Parent then
			warningMarker:Destroy()
		end

		local bomb = context:TrackInstance(Instance.new("Part"))
		bomb.Name = "CrocodileBomb"
		bomb.Shape = Enum.PartType.Ball
		bomb.Anchored = true
		bomb.CanCollide = false
		bomb.Material = Enum.Material.Metal
		bomb.Color = Color3.fromRGB(70, 70, 70)
		bomb.Size = Vector3.new(7, 7, 7)
		bomb.Position = platformPart.Position + Vector3.new(0, eventConfig.BombHeight, 0)
		bomb.Parent = Workspace

		local impactPosition = platformPart.Position + Vector3.new(0, 4, 0)
		local bombTween = TweenService:Create(
			bomb,
			TweenInfo.new(eventConfig.DropDuration, Enum.EasingStyle.Linear),
			{ Position = impactPosition }
		)
		bombTween:Play()

		context:Schedule(eventConfig.DropDuration, function()
			if not bomb.Parent then
				return
			end

			local blast = context:TrackInstance(Instance.new("Part"))
			blast.Name = "BombBlast"
			blast.Shape = Enum.PartType.Ball
			blast.Anchored = true
			blast.CanCollide = false
			blast.Material = Enum.Material.Neon
			blast.Color = Color3.fromRGB(255, 125, 82)
			blast.Transparency = 0.35
			blast.Size = Vector3.new(eventConfig.ExplosionRadius * 2, eventConfig.ExplosionRadius * 2, eventConfig.ExplosionRadius * 2)
			blast.Position = impactPosition
			blast.Parent = Workspace

			for _, player in ipairs(context:GetPlayersInRadius(impactPosition, eventConfig.ExplosionRadius)) do
				if context:DamagePlayer(player, eventConfig.Damage, "Bomb") then
					local rootPart = context:GetRootPart(player)
					if rootPart then
						local offset = rootPart.Position - impactPosition
						local unitOffset = offset.Magnitude > 0.001 and offset.Unit or Vector3.new(0, 1, 0)
						local impulse = unitOffset * eventConfig.KnockbackHorizontal + Vector3.new(0, eventConfig.KnockbackVertical, 0)
						context:ApplyKnockback(player, impulse)
					end
				end
			end

			task.delay(0.3, function()
				if bomb.Parent then
					bomb:Destroy()
				end
				if blast.Parent then
					blast:Destroy()
				end
			end)
		end)
	end)
end

function BombordiroCrocodileBombEvent.Cleanup(_context)
end

return BombordiroCrocodileBombEvent
