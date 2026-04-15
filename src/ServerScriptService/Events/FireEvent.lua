local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FireEvent = {}

local function trackInstance(context, instance)
	table.insert(context.CreatedInstances, instance)
	return instance
end

local function getPlayersTouchingHitbox(hitbox)
	local touchingPlayers = {}
	local seen = {}

	for _, part in ipairs(Workspace:GetPartsInPart(hitbox)) do
		local character = part:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)

		if player and not seen[player] then
			seen[player] = true
			table.insert(touchingPlayers, player)
		end
	end

	return touchingPlayers
end

function FireEvent.Start(context)
	local platformData = context.PlatformManager:GetRandomEnabledPlatform(context.Random)
	if not platformData then
		return
	end

	local eventConfig = context.Config.Events.FireEvent
	local platformPart = platformData.Part

	context.Remotes.Announcement:FireAllClients(("Platform %d is burning"):format(platformData.Index))

	local hitbox = trackInstance(context, Instance.new("Part"))
	hitbox.Name = "FireHitbox"
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Transparency = 1
	hitbox.Size = Vector3.new(platformPart.Size.X - 2, 6, platformPart.Size.Z - 2)
	hitbox.CFrame = platformPart.CFrame + Vector3.new(0, 4, 0)
	hitbox.Parent = workspace

	local visuals = trackInstance(context, Instance.new("Folder"))
	visuals.Name = "FireVisuals"
	visuals.Parent = workspace

	for index = 1, 4 do
		local flame = Instance.new("Part")
		flame.Name = ("Flame_%d"):format(index)
		flame.Anchored = true
		flame.CanCollide = false
		flame.Material = Enum.Material.Neon
		flame.Color = index % 2 == 0 and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(255, 85, 0)
		flame.Size = Vector3.new(3, 6, 3)

		local offsetX = context.Random:NextNumber(-7, 7)
		local offsetZ = context.Random:NextNumber(-7, 7)
		flame.CFrame = platformPart.CFrame + Vector3.new(offsetX, 4, offsetZ)
		flame.Parent = visuals
	end

	task.spawn(function()
		local tickRate = eventConfig.TickRate
		local deadline = os.clock() + context.Duration

		while context.EventData.Active and os.clock() < deadline do
			for _, player in ipairs(getPlayersTouchingHitbox(hitbox)) do
				context.PlayerStateManager:DamagePlayer(player, eventConfig.DamagePerTick, "Fire")
			end

			task.wait(tickRate)
		end
	end)
end

function FireEvent.Cleanup(context)
	context.EventData.Active = false
end

return FireEvent
