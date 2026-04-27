local Workspace = game:GetService("Workspace")

local MapBuilder = {}

local ARENA_FOLDER_NAME = "RoundArena"
local GENERATED_DECOR_FOLDER_NAME = "GeneratedMapDecor"

local HOUSE_THEMES = {
	"TRALALERO",
	"BOMBORDIRO",
	"LIRILI",
	"PATATIM",
	"MEOWL",
	"SLAPBOX",
	"ROCKET",
	"SWORD",
	"LAST STAND",
}

local PLATFORM_PALETTE = {
	{ Floor = Color3.fromRGB(237, 182, 118), Accent = Color3.fromRGB(128, 74, 43), Trim = Color3.fromRGB(255, 240, 196) },
	{ Floor = Color3.fromRGB(112, 178, 115), Accent = Color3.fromRGB(59, 103, 62), Trim = Color3.fromRGB(200, 244, 204) },
	{ Floor = Color3.fromRGB(116, 194, 226), Accent = Color3.fromRGB(49, 101, 120), Trim = Color3.fromRGB(217, 246, 255) },
	{ Floor = Color3.fromRGB(223, 120, 117), Accent = Color3.fromRGB(132, 48, 55), Trim = Color3.fromRGB(255, 215, 215) },
	{ Floor = Color3.fromRGB(244, 214, 114), Accent = Color3.fromRGB(163, 118, 34), Trim = Color3.fromRGB(255, 244, 191) },
	{ Floor = Color3.fromRGB(120, 134, 221), Accent = Color3.fromRGB(58, 68, 132), Trim = Color3.fromRGB(221, 227, 255) },
	{ Floor = Color3.fromRGB(231, 146, 202), Accent = Color3.fromRGB(128, 52, 108), Trim = Color3.fromRGB(255, 226, 245) },
	{ Floor = Color3.fromRGB(168, 172, 180), Accent = Color3.fromRGB(79, 83, 93), Trim = Color3.fromRGB(230, 233, 240) },
	{ Floor = Color3.fromRGB(108, 220, 192), Accent = Color3.fromRGB(31, 110, 93), Trim = Color3.fromRGB(213, 255, 247) },
}

local function create(className, properties)
	local instance = Instance.new(className)
	local parent = properties and properties.Parent or nil

	if properties then
		for propertyName, value in pairs(properties) do
			if propertyName ~= "Parent" then
				instance[propertyName] = value
			end
		end
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function markGenerated(instance)
	instance:SetAttribute("GeneratedByMapBuilder", true)
	return instance
end

local function getOrCreateFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	return create("Folder", {
		Name = name,
		Parent = parent,
	})
end

local function clearChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		child:Destroy()
	end
end

local function createPart(parent, properties)
	return create("Part", properties)
end

local function createLight(parent, brightness, range, color)
	return create("PointLight", {
		Parent = parent,
		Brightness = brightness,
		Range = range,
		Color = color,
	})
end

local function createBillboard(parent, adornee, title, subtitle, size)
	local billboard = create("BillboardGui", {
		Name = "ThemeBillboard",
		Parent = parent,
		Adornee = adornee,
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 180,
		Size = size or UDim2.fromOffset(200, 64),
		StudsOffsetWorldSpace = Vector3.new(0, 0, 0),
	})

	local frame = create("Frame", {
		Parent = billboard,
		BackgroundColor3 = Color3.fromRGB(15, 18, 24),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	})

	create("UICorner", {
		Parent = frame,
		CornerRadius = UDim.new(0, 12),
	})

	create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 26),
		Font = Enum.Font.GothamBlack,
		Text = title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(1, -20, 0, 18),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextColor3 = Color3.fromRGB(225, 233, 255),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
end

local function createSurfaceLabel(part, face, title, subtitle)
	local surfaceGui = create("SurfaceGui", {
		Parent = part,
		Face = face,
		AlwaysOnTop = true,
		LightInfluence = 0,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 40,
	})

	local frame = create("Frame", {
		Parent = surfaceGui,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})

	create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.08, 0.12),
		Size = UDim2.fromScale(0.84, 0.44),
		Font = Enum.Font.GothamBlack,
		Text = title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
	})

	create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.08, 0.56),
		Size = UDim2.fromScale(0.84, 0.22),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextColor3 = Color3.fromRGB(230, 236, 255),
		TextScaled = true,
	})
end

local function createRailings(parent, deckPart, postColor)
	local size = deckPart.Size
	local y = size.Y * 0.5 + 3
	local railHeight = 5
	local railThickness = 1
	local railInset = 1

	local rails = {
		{ Offset = Vector3.new(0, y, size.Z * 0.5 - railInset), Size = Vector3.new(size.X - 4, railHeight, railThickness) },
		{ Offset = Vector3.new(0, y, -size.Z * 0.5 + railInset), Size = Vector3.new(size.X - 4, railHeight, railThickness) },
		{ Offset = Vector3.new(size.X * 0.5 - railInset, y, 0), Size = Vector3.new(railThickness, railHeight, size.Z - 4) },
		{ Offset = Vector3.new(-size.X * 0.5 + railInset, y, 0), Size = Vector3.new(railThickness, railHeight, size.Z - 4) },
	}

	for _, railData in ipairs(rails) do
		createPart(parent, {
			Name = "Railing",
			Anchored = true,
			CanCollide = true,
			Material = Enum.Material.Metal,
			Color = postColor,
			Size = railData.Size,
			CFrame = deckPart.CFrame * CFrame.new(railData.Offset),
		})
	end
end

local function createBridge(parent, startPosition, endPosition, width)
	local direction = endPosition - startPosition
	local length = direction.Magnitude
	local center = startPosition + direction * 0.5

	return createPart(parent, {
		Name = "ObservationBridge",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(89, 99, 123),
		Size = Vector3.new(width, 2, length),
		CFrame = CFrame.lookAt(center, endPosition),
	})
end

local function createViewerProp(parent, cframe)
	local base = createPart(parent, {
		Name = "ViewerBase",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(64, 69, 81),
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.8, 2.8, 1.8),
		CFrame = cframe * CFrame.Angles(0, 0, math.rad(90)),
	})

	local post = createPart(parent, {
		Name = "ViewerPost",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(115, 121, 141),
		Size = Vector3.new(0.7, 4, 0.7),
		CFrame = cframe * CFrame.new(0, 2.5, 0),
	})

	local scope = createPart(parent, {
		Name = "ViewerScope",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(209, 214, 228),
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 3.6, 1.4),
		CFrame = cframe * CFrame.new(0, 4.7, -1.4) * CFrame.Angles(math.rad(18), 0, math.rad(90)),
	})

	createLight(scope, 1.2, 10, Color3.fromRGB(130, 200, 255))

	return base, post, scope
end

local function createSkyPillar(parent, position, color)
	local pillar = createPart(parent, {
		Name = "SkyPillar",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(56, 67, 89),
		Size = Vector3.new(6, 46, 6),
		CFrame = CFrame.new(position + Vector3.new(0, 23, 0)),
	})

	local orb = createPart(parent, {
		Name = "SkyOrb",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = color,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5, 5, 5),
		CFrame = CFrame.new(position + Vector3.new(0, 47, 0)),
	})

	createLight(orb, 1.8, 22, color)

	return pillar, orb
end

local function createPoster(parent, cframe, size, title, subtitle)
	local board = createPart(parent, {
		Name = "PosterBoard",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(27, 31, 40),
		Size = size,
		CFrame = cframe,
	})

	createSurfaceLabel(board, Enum.NormalId.Front, title, subtitle)
	return board
end

local function buildHousePlatform(parent, config, builderConfig, index, row, column)
	local platformSize = config.World.PlatformSize
	local spacing = config.World.PlatformSpacing
	local halfGrid = (config.World.PlatformGridSize - 1) * 0.5
	local themeName = HOUSE_THEMES[index] or ("HOUSE " .. tostring(index))
	local palette = PLATFORM_PALETTE[((index - 1) % #PLATFORM_PALETTE) + 1]

	local x = (column - 1 - halfGrid) * spacing
	local z = (row - 1 - halfGrid) * spacing
	local position = Vector3.new(x, config.World.PlatformHeight, z)
	local focusPosition = Vector3.new(0, config.World.PlatformHeight, 0)
	local localFrame = CFrame.lookAt(position, focusPosition)

	local model = markGenerated(create("Model", {
		Name = string.format("House_%02d", index),
		Parent = parent,
	}))
	model:SetAttribute("PlatformIndex", index)

	local platform = markGenerated(createPart(model, {
		Name = "Floor",
		Anchored = true,
		CanCollide = true,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
		Material = Enum.Material.Concrete,
		Color = palette.Floor,
		Size = platformSize,
		CFrame = CFrame.new(position),
	}))
	platform:SetAttribute("PlatformIndex", index)
	platform:SetAttribute("OriginalColorR", palette.Floor.R)
	platform:SetAttribute("OriginalColorG", palette.Floor.G)
	platform:SetAttribute("OriginalColorB", palette.Floor.B)
	model.PrimaryPart = platform

	createPart(model, {
		Name = "UnderTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Slate,
		Color = palette.Accent,
		Size = Vector3.new(platformSize.X + 2, 2, platformSize.Z + 2),
		CFrame = CFrame.new(position - Vector3.new(0, 2, 0)),
	})

	for _, offset in ipairs({
		Vector3.new(-8, -7, -8),
		Vector3.new(8, -7, -8),
		Vector3.new(-8, -7, 8),
		Vector3.new(8, -7, 8),
	}) do
		createPart(model, {
			Name = "Support",
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(70, 76, 88),
			Size = Vector3.new(2, 12, 2),
			CFrame = platform.CFrame * CFrame.new(offset),
		})
	end

	local function localDecor(name, offset, size, color, material, rotation, shape)
		return createPart(model, {
			Name = name,
			Anchored = true,
			CanCollide = false,
			Material = material,
			Color = color,
			Shape = shape,
			Size = size,
			CFrame = localFrame * CFrame.new(offset) * (rotation or CFrame.new()),
		})
	end

	localDecor("BackWall", Vector3.new(0, 4.3, 8.2), Vector3.new(14, 8, 1), palette.Accent, Enum.Material.WoodPlanks)
	localDecor("LeftWall", Vector3.new(-6.6, 4.3, 4.1), Vector3.new(1, 8, 8), palette.Accent, Enum.Material.WoodPlanks)
	localDecor("RightWall", Vector3.new(6.6, 4.3, 4.1), Vector3.new(1, 8, 8), palette.Accent, Enum.Material.WoodPlanks)
	localDecor("Roof", Vector3.new(0, 8.9, 4.8), Vector3.new(16, 1, 11), palette.Trim, Enum.Material.SmoothPlastic)
	localDecor("Awning", Vector3.new(0, 6.4, -0.2), Vector3.new(12, 0.8, 4), palette.Trim, Enum.Material.SmoothPlastic)
	localDecor("WindowLeft", Vector3.new(-3.6, 4.7, 7.7), Vector3.new(2.4, 2.6, 0.25), Color3.fromRGB(192, 240, 255), Enum.Material.Glass)
	localDecor("WindowRight", Vector3.new(3.6, 4.7, 7.7), Vector3.new(2.4, 2.6, 0.25), Color3.fromRGB(192, 240, 255), Enum.Material.Glass)
	localDecor("DoorPanel", Vector3.new(0, 3.6, 1.1), Vector3.new(5.5, 3.2, 0.35), Color3.fromRGB(36, 38, 49), Enum.Material.SmoothPlastic)

	local signBoard = localDecor("FrontSign", Vector3.new(0, 4.8, -1.7), Vector3.new(8, 3, 0.35), Color3.fromRGB(28, 33, 45), Enum.Material.SmoothPlastic)
	createSurfaceLabel(signBoard, Enum.NormalId.Front, themeName, "SURVIVE")

	local billboardAnchor = localDecor("BillboardAnchor", Vector3.new(0, builderConfig.HouseSignHeight, 4.2), Vector3.new(1, 1, 1), palette.Trim, Enum.Material.SmoothPlastic)
	billboardAnchor.Transparency = 1
	createBillboard(model, billboardAnchor, themeName, ("HOUSE %d"):format(index))

	local leftLamp = localDecor("LampLeft", Vector3.new(-4.4, 6.2, -0.6), Vector3.new(0.9, 0.9, 0.9), palette.Trim, Enum.Material.Neon, nil, Enum.PartType.Ball)
	local rightLamp = localDecor("LampRight", Vector3.new(4.4, 6.2, -0.6), Vector3.new(0.9, 0.9, 0.9), palette.Trim, Enum.Material.Neon, nil, Enum.PartType.Ball)
	createLight(leftLamp, 1.1, 10, palette.Trim)
	createLight(rightLamp, 1.1, 10, palette.Trim)

	local variant = ((index - 1) % 3) + 1
	if variant == 1 then
		localDecor("AntennaPole", Vector3.new(5.4, 11.5, 8), Vector3.new(0.35, 5.5, 0.35), Color3.fromRGB(82, 89, 104), Enum.Material.Metal)
		localDecor("AntennaDish", Vector3.new(5.1, 10.3, 6.8), Vector3.new(0.4, 2.4, 2.4), Color3.fromRGB(212, 223, 242), Enum.Material.SmoothPlastic, CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	elseif variant == 2 then
		localDecor("TankLegA", Vector3.new(-4.4, 9.3, 7.1), Vector3.new(0.4, 2.2, 0.4), Color3.fromRGB(97, 103, 121), Enum.Material.Metal)
		localDecor("TankLegB", Vector3.new(-6.2, 9.3, 7.1), Vector3.new(0.4, 2.2, 0.4), Color3.fromRGB(97, 103, 121), Enum.Material.Metal)
		localDecor("WaterTank", Vector3.new(-5.3, 10.4, 7.1), Vector3.new(2.2, 3.6, 2.2), Color3.fromRGB(192, 202, 217), Enum.Material.SmoothPlastic, CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	else
		localDecor("CrateA", Vector3.new(5.2, 2.5, -4.6), Vector3.new(3, 3, 3), Color3.fromRGB(134, 94, 52), Enum.Material.WoodPlanks)
		localDecor("CrateB", Vector3.new(6.5, 5.1, -4), Vector3.new(2.4, 2.4, 2.4), Color3.fromRGB(156, 113, 69), Enum.Material.WoodPlanks)
		local arrow = localDecor("NeonArrow", Vector3.new(-5.8, 5.8, -2.8), Vector3.new(0.8, 3.8, 0.8), palette.Trim, Enum.Material.Neon)
		createLight(arrow, 1, 8, palette.Trim)
	end
end

local function buildArenaDecor(parent, config, builderConfig)
	local gridHalf = config.World.PlatformSpacing * (config.World.PlatformGridSize - 1) * 0.5 + config.World.PlatformSize.X
	local arenaY = config.World.PlatformHeight

	markGenerated(createPart(parent, {
		Name = "VoidBackdrop",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(14, 18, 27),
		Transparency = 0.15,
		Size = builderConfig.VoidBackdropSize,
		CFrame = CFrame.new(0, builderConfig.VoidBackdropY, 0),
	}))

	for _, position in ipairs({
		Vector3.new(-gridHalf - 18, arenaY, -gridHalf - 18),
		Vector3.new(gridHalf + 18, arenaY, -gridHalf - 18),
		Vector3.new(-gridHalf - 18, arenaY, gridHalf + 18),
		Vector3.new(gridHalf + 18, arenaY, gridHalf + 18),
	}) do
		createSkyPillar(parent, position, Color3.fromRGB(118, 198, 255))
	end

	createPoster(
		parent,
		CFrame.new(0, arenaY + 34, -gridHalf - 34),
		Vector3.new(30, 14, 1),
		"HOUSE MAYHEM",
		"LAST PLAYER ALIVE WINS"
	)
end

local function buildLobbyAndObservation(parent, config, builderConfig)
	local placedMapConfig = config.World.PlacedMap
	local lobbyCenter = config.World.LobbyPosition
	local lobbyIsland = markGenerated(createPart(parent, {
		Name = "LobbyIsland",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(37, 45, 62),
		Size = builderConfig.LobbyIslandSize,
		CFrame = CFrame.new(lobbyCenter),
	}))

	markGenerated(createPart(parent, {
		Name = "LobbyUnderside",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(23, 27, 39),
		Size = Vector3.new(builderConfig.LobbyIslandSize.X - 6, 4, builderConfig.LobbyIslandSize.Z - 6),
		CFrame = lobbyIsland.CFrame * CFrame.new(0, -3, 0),
	}))

	local lobbySpawn = markGenerated(createPart(parent, {
		Name = placedMapConfig.LobbySpawnPartName,
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(103, 190, 255),
		Size = Vector3.new(16, 1, 16),
		CFrame = CFrame.new(lobbyCenter + Vector3.new(0, 1.5, 0)),
	}))
	createLight(lobbySpawn, 2, 20, Color3.fromRGB(103, 190, 255))
	createBillboard(parent, lobbySpawn, "LOBBY SPAWN", "WAIT FOR THE NEXT ROUND", UDim2.fromOffset(240, 72))

	createRailings(parent, lobbyIsland, Color3.fromRGB(111, 123, 151))

	createPoster(
		parent,
		lobbyIsland.CFrame * CFrame.new(0, 8, -builderConfig.LobbyIslandSize.Z * 0.5 + 1),
		Vector3.new(22, 8, 1),
		"ROUND LOBBY",
		"JUMP IN WHEN READY"
	)

	local observationCenter = lobbyCenter + builderConfig.ObservationOffset
	local observationDeck = markGenerated(createPart(parent, {
		Name = "ObservationDeck",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(51, 59, 80),
		Size = builderConfig.ObservationDeckSize,
		CFrame = CFrame.new(observationCenter),
	}))

	markGenerated(createPart(parent, {
		Name = "ObservationUnderside",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(28, 32, 44),
		Size = Vector3.new(builderConfig.ObservationDeckSize.X - 4, 3, builderConfig.ObservationDeckSize.Z - 4),
		CFrame = observationDeck.CFrame * CFrame.new(0, -2.5, 0),
	}))

	createRailings(parent, observationDeck, Color3.fromRGB(142, 151, 178))

	local bridgeStart = lobbyIsland.Position + Vector3.new(builderConfig.LobbyIslandSize.X * 0.5 - 8, 2, 0)
	local bridgeEnd = observationDeck.Position + Vector3.new(-builderConfig.ObservationDeckSize.X * 0.5 + 8, 2, 0)
	createBridge(parent, bridgeStart, bridgeEnd, builderConfig.BridgeWidth)

	createViewerProp(parent, observationDeck.CFrame * CFrame.new(-8, 1, -7))
	createViewerProp(parent, observationDeck.CFrame * CFrame.new(8, 1, -7))

	createPoster(
		parent,
		observationDeck.CFrame * CFrame.new(0, 8.5, builderConfig.ObservationDeckSize.Z * 0.5 - 1) * CFrame.Angles(0, math.rad(180), 0),
		Vector3.new(20, 8, 1),
		"OBSERVATION",
		"WATCH THE CHAOS"
	)

	createPoster(
		parent,
		observationDeck.CFrame * CFrame.new(0, 13.5, -builderConfig.ObservationDeckSize.Z * 0.5 + 1),
		Vector3.new(28, 10, 1),
		"EVENT ZONE",
		"SURVIVE THE MEME STORM"
	)
end

function MapBuilder.Build(config)
	local builderConfig = config.World.MapBuilder
	local placedMapConfig = config.World.PlacedMap
	if not builderConfig or not builderConfig.Enabled or not placedMapConfig or not placedMapConfig.Enabled then
		return
	end

	local arena = getOrCreateFolder(Workspace, ARENA_FOLDER_NAME)
	local customMapFolder = arena:FindFirstChild(placedMapConfig.PlatformsFolderName) or Workspace:FindFirstChild(placedMapConfig.PlatformsFolderName)
	if builderConfig.RespectExistingCustomMap and customMapFolder and not customMapFolder:GetAttribute("GeneratedByMapBuilder") then
		return
	end

	local mapFolder = getOrCreateFolder(arena, placedMapConfig.PlatformsFolderName)
	local decorFolder = getOrCreateFolder(arena, GENERATED_DECOR_FOLDER_NAME)
	markGenerated(mapFolder)
	markGenerated(decorFolder)

	clearChildren(mapFolder)
	clearChildren(decorFolder)

	for row = 1, config.World.PlatformGridSize do
		for column = 1, config.World.PlatformGridSize do
			local index = ((row - 1) * config.World.PlatformGridSize) + column
			buildHousePlatform(mapFolder, config, builderConfig, index, row, column)
		end
	end

	buildArenaDecor(decorFolder, config, builderConfig)
	buildLobbyAndObservation(decorFolder, config, builderConfig)
end

return MapBuilder
