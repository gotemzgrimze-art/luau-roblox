local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TralaleloTralalaTsunamiEvent = {
	Name = "TralaleloTralalaTsunamiEvent",
	Weight = 10,
	Duration = 6,
}

function TralaleloTralalaTsunamiEvent.CanRun(context)
	for rowIndex = 1, context.Config.World.PlatformGridSize do
		if #context:GetPlayersStandingOnRow(rowIndex) > 0 then
			return true
		end
	end

	return false
end

function TralaleloTralalaTsunamiEvent.Start(context)
	local eventConfig = context.EventConfig
	local validRows = {}

	for rowIndex = 1, context.Config.World.PlatformGridSize do
		if #context:GetPlayersStandingOnRow(rowIndex) > 0 then
			table.insert(validRows, rowIndex)
		end
	end

	if #validRows == 0 then
		return
	end

	local rowIndex = validRows[context.Random:NextInteger(1, #validRows)]
	local rowPlatforms = context:GetPlatformsInRow(rowIndex)
	local directionSign = context.Random:NextInteger(0, 1) == 0 and -1 or 1

	local minX = math.huge
	local maxX = -math.huge
	local zSum = 0
	local topY = -math.huge
	local warningParts = {}

	for _, platformData in ipairs(rowPlatforms) do
		local part = platformData.Part
		local halfX = part.Size.X * 0.5
		minX = math.min(minX, part.Position.X - halfX)
		maxX = math.max(maxX, part.Position.X + halfX)
		zSum += part.Position.Z
		topY = math.max(topY, part.Position.Y + part.Size.Y * 0.5)

		local warningPart = context:TrackInstance(Instance.new("Part"))
		warningPart.Name = "TsunamiWarning"
		warningPart.Anchored = true
		warningPart.CanCollide = false
		warningPart.Material = Enum.Material.Neon
		warningPart.Color = Color3.fromRGB(67, 180, 255)
		warningPart.Size = Vector3.new(part.Size.X - 2, 0.3, part.Size.Z - 2)
		warningPart.CFrame = part.CFrame + Vector3.new(0, 1.25, 0)
		warningPart.Parent = Workspace
		table.insert(warningParts, warningPart)
	end

	local rowCenterZ = zSum / #rowPlatforms
	local startX = directionSign == 1 and (minX - eventConfig.WaveThickness) or (maxX + eventConfig.WaveThickness)
	local endX = directionSign == 1 and (maxX + eventConfig.WaveThickness) or (minX - eventConfig.WaveThickness)

	context:Announce(("Tralalelo Tralala tsunami warning on row %d"):format(rowIndex))

	context:Schedule(eventConfig.WarningDuration, function()
		for _, warningPart in ipairs(warningParts) do
			if warningPart.Parent then
				warningPart:Destroy()
			end
		end

		local wave = context:TrackInstance(Instance.new("Part"))
		wave.Name = "TsunamiWave"
		wave.Anchored = true
		wave.CanCollide = false
		wave.Material = Enum.Material.Neon
		wave.Color = Color3.fromRGB(45, 170, 255)
		wave.Transparency = 0.15
		wave.Size = Vector3.new(eventConfig.WaveThickness, eventConfig.WaveHeight, context.Config.World.PlatformSize.Z + 10)
		wave.CFrame = CFrame.new(startX, topY + eventConfig.WaveHeight * 0.5 - 1, rowCenterZ)
		wave.Parent = Workspace

		local travelDistance = math.abs(endX - startX)
		local travelDuration = math.max(0.5, travelDistance / eventConfig.WaveSpeed)
		local elapsed = 0
		local hitPlayers = {}

		local sweepConnection
		sweepConnection = RunService.Heartbeat:Connect(function(deltaTime)
			if not context:IsActive() or not wave.Parent then
				sweepConnection:Disconnect()
				return
			end

			elapsed += deltaTime

			local alpha = math.clamp(elapsed / travelDuration, 0, 1)
			local currentX = startX + (endX - startX) * alpha
			wave.CFrame = CFrame.new(currentX, topY + eventConfig.WaveHeight * 0.5 - 1, rowCenterZ)

			for _, player in ipairs(context:GetPlayersInBox(wave.CFrame, wave.Size)) do
				if not hitPlayers[player] then
					hitPlayers[player] = true
					context:DamagePlayer(player, eventConfig.Damage, "Tsunami")
					context:ApplyKnockback(
						player,
						Vector3.new(directionSign * eventConfig.KnockbackHorizontal, eventConfig.KnockbackVertical, 0)
					)
				end
			end

			if alpha >= 1 then
				sweepConnection:Disconnect()
			end
		end)

		context:TrackConnection(sweepConnection)
	end)
end

function TralaleloTralalaTsunamiEvent.Cleanup(_context)
end

return TralaleloTralalaTsunamiEvent
