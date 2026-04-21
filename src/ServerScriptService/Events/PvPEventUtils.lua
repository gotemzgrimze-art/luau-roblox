local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PvPEventUtils = {}
local DEFAULT_SELF_DAMAGE_SCALE = 0.4

local function createTool(toolName, color, size)
	local tool = Instance.new("Tool")
	tool.Name = toolName
	tool.ToolTip = toolName
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = size
	handle.Color = color
	handle.Material = Enum.Material.SmoothPlastic
	handle.Massless = true
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Parent = tool

	return tool
end

local function updateAmmoName(tool, baseName, ammo)
	if ammo > 0 then
		tool.Name = ("%s (%d)"):format(baseName, ammo)
	else
		tool.Name = ("%s (Empty)"):format(baseName)
	end
end

local function getNearestTarget(context, sourcePosition, candidatePlayers)
	local nearestPlayer = nil
	local nearestDistance = math.huge

	for _, candidatePlayer in ipairs(candidatePlayers) do
		local rootPart = context:GetRootPart(candidatePlayer)
		if rootPart then
			local distance = (rootPart.Position - sourcePosition).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestPlayer = candidatePlayer
			end
		end
	end

	return nearestPlayer
end

function PvPEventUtils.GrantMeleeTools(context, players, options)
	for _, player in ipairs(players) do
		local tool = createTool(options.ToolName, options.HandleColor, options.HandleSize)
		context:GrantTemporaryTool(player, tool)

		local lastAttackAt = 0
		context:TrackConnection(tool.Activated:Connect(function()
			if not context:IsActive() or not context:IsPlayerAlive(player) then
				return
			end

			local now = os.clock()
			if now - lastAttackAt < options.Cooldown then
				return
			end

			local rootPart = context:GetRootPart(player)
			if not rootPart then
				return
			end

			lastAttackAt = now

			local lookVector = rootPart.CFrame.LookVector
			local center = rootPart.Position + lookVector * (options.Range * 0.5 + 2) + Vector3.new(0, 2.5, 0)
			local hitboxCFrame = CFrame.lookAt(center, center + lookVector)
			local hitPlayers = context:GetPlayersInBox(hitboxCFrame, options.HitboxSize, { player })
			local targetPlayer = getNearestTarget(context, rootPart.Position, hitPlayers)

			if targetPlayer and context:DamagePlayerFromPlayer(player, targetPlayer, options.Damage, options.Reason) then
				local impulse = lookVector * options.KnockbackHorizontal + Vector3.new(0, options.KnockbackVertical, 0)
				context:ApplyKnockback(targetPlayer, impulse)
			end
		end))
	end
end

local function createBlastVisual(context, position, radius)
	local blast = context:TrackInstance(Instance.new("Part"))
	blast.Name = "RocketBlast"
	blast.Shape = Enum.PartType.Ball
	blast.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	blast.Position = position
	blast.Anchored = true
	blast.CanCollide = false
	blast.Material = Enum.Material.Neon
	blast.Color = Color3.fromRGB(255, 164, 82)
	blast.Transparency = 0.4
	blast.Parent = Workspace

	task.delay(0.25, function()
		if blast.Parent then
			blast:Destroy()
		end
	end)
end

local function explodeRocket(context, ownerPlayer, options, position)
	createBlastVisual(context, position, options.ExplosionRadius)

	local affectedPlayers = context:GetPlayersInRadius(position, options.ExplosionRadius)

	for _, targetPlayer in ipairs(affectedPlayers) do
		local rootPart = context:GetRootPart(targetPlayer)
		if rootPart then
			local direction = rootPart.Position - position
			local unitDirection = direction.Magnitude > 0.001 and direction.Unit or Vector3.new(0, 1, 0)
			local impulse = unitDirection * options.KnockbackHorizontal + Vector3.new(0, options.KnockbackVertical, 0)

			if targetPlayer == ownerPlayer then
				local selfDamage = math.max(1, math.floor(options.Damage * (options.SelfDamageScale or DEFAULT_SELF_DAMAGE_SCALE)))
				if context:DamagePlayer(targetPlayer, selfDamage, options.Reason) then
					context:ApplyKnockback(targetPlayer, impulse)
				end
			elseif context:DamagePlayerFromPlayer(ownerPlayer, targetPlayer, options.Damage, options.Reason) then
				context:ApplyKnockback(targetPlayer, impulse)
			end
		end
	end
end

function PvPEventUtils.GrantRocketTools(context, players, options)
	for _, player in ipairs(players) do
		local ammo = options.Ammo
		local tool = createTool(options.ToolName, options.HandleColor, options.HandleSize)
		updateAmmoName(tool, options.ToolName, ammo)
		context:GrantTemporaryTool(player, tool)

		local lastFireAt = 0
		context:TrackConnection(tool.Activated:Connect(function()
			if not context:IsActive() or not context:IsPlayerAlive(player) or ammo <= 0 then
				return
			end

			local now = os.clock()
			if now - lastFireAt < options.Cooldown then
				return
			end

			local rootPart = context:GetRootPart(player)
			if not rootPart then
				return
			end

			lastFireAt = now
			ammo -= 1
			updateAmmoName(tool, options.ToolName, ammo)

			local direction = rootPart.CFrame.LookVector
			if direction.Magnitude < 0.001 then
				direction = Vector3.new(0, 0, -1)
			else
				direction = direction.Unit
			end

			local startPosition = rootPart.Position + Vector3.new(0, 2.5, 0) + direction * 5
			local rocket = context:TrackInstance(Instance.new("Part"))
			rocket.Name = "EventRocket"
			rocket.Size = Vector3.new(1, 1, 3)
			rocket.CFrame = CFrame.lookAt(startPosition, startPosition + direction)
			rocket.Anchored = true
			rocket.CanCollide = false
			rocket.Material = Enum.Material.Metal
			rocket.Color = Color3.fromRGB(255, 92, 92)
			rocket.Parent = Workspace

			local previousPosition = startPosition
			local lifeRemaining = options.ProjectileLifetime

			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			raycastParams.FilterDescendantsInstances = { rocket, player.Character }

			local projectileConnection
			projectileConnection = RunService.Heartbeat:Connect(function(deltaTime)
				if not context:IsActive() or not rocket.Parent then
					projectileConnection:Disconnect()
					return
				end

				lifeRemaining -= deltaTime
				if lifeRemaining <= 0 then
					explodeRocket(context, player, options, previousPosition)
					rocket:Destroy()
					projectileConnection:Disconnect()
					return
				end

				local nextPosition = previousPosition + direction * options.ProjectileSpeed * deltaTime
				local raycastResult = Workspace:Raycast(previousPosition, nextPosition - previousPosition, raycastParams)

				if raycastResult then
					rocket.Position = raycastResult.Position
					explodeRocket(context, player, options, raycastResult.Position)
					rocket:Destroy()
					projectileConnection:Disconnect()
					return
				end

				rocket.CFrame = CFrame.lookAt(nextPosition, nextPosition + direction)
				previousPosition = nextPosition
			end)

			context:TrackConnection(projectileConnection)
		end))
	end
end

return PvPEventUtils
