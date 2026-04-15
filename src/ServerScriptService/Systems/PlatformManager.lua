local Workspace = game:GetService("Workspace")

local PlatformManager = {}
PlatformManager.__index = PlatformManager

local ARENA_FOLDER_NAME = "RoundArena"
local PLATFORMS_FOLDER_NAME = "Platforms"
local LOBBY_PART_NAME = "LobbyPad"

function PlatformManager.new(config)
	local self = setmetatable({}, PlatformManager)

	self.Config = config
	self.Random = Random.new()
	self.Platforms = {}
	self.Assignments = {}

	self:_buildArena()

	return self
end

function PlatformManager:_buildArena()
	local arena = Workspace:FindFirstChild(ARENA_FOLDER_NAME)
	if not arena then
		arena = Instance.new("Folder")
		arena.Name = ARENA_FOLDER_NAME
		arena.Parent = Workspace
	end

	self.Arena = arena

	local platformsFolder = arena:FindFirstChild(PLATFORMS_FOLDER_NAME)
	if not platformsFolder then
		platformsFolder = Instance.new("Folder")
		platformsFolder.Name = PLATFORMS_FOLDER_NAME
		platformsFolder.Parent = arena
	end

	self.PlatformFolder = platformsFolder
	self:_buildLobby()
	self:_buildPlatforms()
end

function PlatformManager:_buildLobby()
	local lobbyPart = self.Arena:FindFirstChild(LOBBY_PART_NAME)
	if not lobbyPart then
		lobbyPart = Instance.new("Part")
		lobbyPart.Name = LOBBY_PART_NAME
		lobbyPart.Anchored = true
		lobbyPart.TopSurface = Enum.SurfaceType.Smooth
		lobbyPart.BottomSurface = Enum.SurfaceType.Smooth
		lobbyPart.Material = Enum.Material.SmoothPlastic
		lobbyPart.Color = Color3.fromRGB(88, 160, 255)
		lobbyPart.Parent = self.Arena
	end

	lobbyPart.Size = self.Config.World.LobbySize
	lobbyPart.CFrame = CFrame.new(self.Config.World.LobbyPosition)
	self.LobbyPart = lobbyPart
	self.LobbySpawnCFrame = lobbyPart.CFrame + Vector3.new(0, 5, 0)
end

function PlatformManager:_buildPlatforms()
	table.clear(self.Platforms)

	local size = self.Config.World.PlatformSize
	local spacing = self.Config.World.PlatformSpacing
	local gridSize = self.Config.World.PlatformGridSize
	local halfGrid = (gridSize - 1) * 0.5

	for row = 1, gridSize do
		for column = 1, gridSize do
			local index = ((row - 1) * gridSize) + column
			local platformName = string.format("Platform_%02d", index)
			local platformPart = self.PlatformFolder:FindFirstChild(platformName)

			if not platformPart then
				platformPart = Instance.new("Part")
				platformPart.Name = platformName
				platformPart.Anchored = true
				platformPart.TopSurface = Enum.SurfaceType.Smooth
				platformPart.BottomSurface = Enum.SurfaceType.Smooth
				platformPart.Parent = self.PlatformFolder
			end

			local x = (column - 1 - halfGrid) * spacing
			local z = (row - 1 - halfGrid) * spacing
			local position = Vector3.new(x, self.Config.World.PlatformHeight, z)

			platformPart.Size = size
			platformPart.CFrame = CFrame.new(position)
			platformPart.Material = Enum.Material.Concrete
			platformPart.Color = Color3.fromRGB(210, 210, 210)
			platformPart.CanCollide = true
			platformPart.Transparency = 0
			platformPart:SetAttribute("PlatformIndex", index)

			self.Platforms[index] = {
				Index = index,
				Part = platformPart,
				SpawnCFrame = platformPart.CFrame + self.Config.World.PlatformSpawnOffset,
				IsEnabled = true,
			}
		end
	end
end

function PlatformManager:GetLobbySpawnCFrame()
	return self.LobbySpawnCFrame
end

function PlatformManager:GetPlatforms()
	return self.Platforms
end

function PlatformManager:GetAssignedPlatform(player)
	return self.Assignments[player]
end

function PlatformManager:GetRandomEnabledPlatform(randomObject)
	local enabledPlatforms = {}

	for _, platformData in ipairs(self.Platforms) do
		if platformData.IsEnabled then
			table.insert(enabledPlatforms, platformData)
		end
	end

	if #enabledPlatforms == 0 then
		return nil
	end

	local rng = randomObject or self.Random
	local index = rng:NextInteger(1, #enabledPlatforms)
	return enabledPlatforms[index]
end

function PlatformManager:ResetRound()
	table.clear(self.Assignments)

	for _, platformData in ipairs(self.Platforms) do
		local part = platformData.Part
		platformData.IsEnabled = true
		part.CanCollide = true
		part.Transparency = 0
		part.Material = Enum.Material.Concrete
		part.Color = Color3.fromRGB(210, 210, 210)
	end
end

function PlatformManager:SetPlatformEnabled(platformData, isEnabled)
	if not platformData then
		return
	end

	platformData.IsEnabled = isEnabled
	platformData.Part.CanCollide = isEnabled
	platformData.Part.Transparency = isEnabled and 0 or 0.8
	platformData.Part.Material = isEnabled and Enum.Material.Concrete or Enum.Material.ForceField
	platformData.Part.Color = isEnabled and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(95, 255, 160)
end

function PlatformManager:_shuffleArray(items)
	for index = #items, 2, -1 do
		local swapIndex = self.Random:NextInteger(1, index)
		items[index], items[swapIndex] = items[swapIndex], items[index]
	end
end

function PlatformManager:AssignPlayers(players)
	table.clear(self.Assignments)

	local availablePlatforms = {}
	for _, platformData in ipairs(self.Platforms) do
		table.insert(availablePlatforms, platformData)
	end

	self:_shuffleArray(availablePlatforms)

	for index, player in ipairs(players) do
		local platformData = availablePlatforms[index]
		if platformData then
			self.Assignments[player] = platformData
			self:TeleportPlayerToPlatform(player, platformData)
		end
	end
end

function PlatformManager:_teleportCharacter(character, targetCFrame)
	character:PivotTo(targetCFrame)

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end
end

function PlatformManager:TeleportPlayerToPlatform(player, platformData)
	local character = player.Character
	if character and platformData then
		self:_teleportCharacter(character, platformData.SpawnCFrame)
	end
end

function PlatformManager:TeleportPlayerToLobby(player)
	local character = player.Character
	if character then
		self:_teleportCharacter(character, self.LobbySpawnCFrame)
	end
end

function PlatformManager:GetPlayersStandingOnPlatform(platformData, players)
	local part = platformData and platformData.Part
	if not part then
		return {}
	end

	local playersOnPlatform = {}
	local size = part.Size
	local halfX = size.X * 0.5
	local halfZ = size.Z * 0.5

	for _, player in ipairs(players) do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		if rootPart then
			local localPosition = part.CFrame:PointToObjectSpace(rootPart.Position)
			local withinX = math.abs(localPosition.X) <= halfX
			local withinZ = math.abs(localPosition.Z) <= halfZ
			local withinY = localPosition.Y >= 0 and localPosition.Y <= 12

			if withinX and withinZ and withinY then
				table.insert(playersOnPlatform, player)
			end
		end
	end

	return playersOnPlatform
end

return PlatformManager
