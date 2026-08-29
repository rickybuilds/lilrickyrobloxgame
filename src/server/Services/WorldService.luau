--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local WorldService = {}

type PartOptions = {
	Name: string,
	Size: Vector3,
	Position: Vector3,
	Color: Color3?,
	Material: Enum.Material?,
	Parent: Instance,
	CanCollide: boolean?,
	CanQuery: boolean?,
	Transparency: number?,
}

local function makePart(options: PartOptions): Part
	local part = Instance.new("Part")
	part.Name = options.Name
	part.Anchored = true
	part.Size = options.Size
	part.Position = options.Position
	part.Color = options.Color or Color3.fromRGB(163, 162, 165)
	part.Material = options.Material or Enum.Material.SmoothPlastic
	part.CanCollide = if options.CanCollide == nil then true else options.CanCollide
	part.CanQuery = if options.CanQuery == nil then true else options.CanQuery
	part.Transparency = options.Transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = options.Parent
	return part
end

local function addSurfaceLabel(part: BasePart, text: string, face: Enum.NormalId?)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "WorldLabel"
	surfaceGui.Face = face or Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 32
	surfaceGui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextStrokeColor3 = Color3.fromRGB(25, 25, 25)
	label.TextStrokeTransparency = 0.35
	label.Parent = surfaceGui
end

local function makeBuildingShell(
	parent: Instance,
	name: string,
	center: Vector3,
	size: Vector3,
	color: Color3,
	signText: string?
): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local building = makePart({
		Name = "Building",
		Size = size,
		Position = center + Vector3.new(0, size.Y / 2, 0),
		Color = color,
		Material = Enum.Material.Concrete,
		Parent = model,
	})

	if signText then
		local sign = makePart({
			Name = "Sign",
			Size = Vector3.new(math.min(size.X - 4, 30), 6, 1),
			Position = center + Vector3.new(0, size.Y * 0.7, -(size.Z / 2 + 0.55)),
			Color = Color3.fromRGB(36, 92, 173),
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
		addSurfaceLabel(sign, signText, Enum.NormalId.Front)
	end

	model.PrimaryPart = building
	return model
end

local function createRoads(parent: Instance)
	local roads = Instance.new("Model")
	roads.Name = "Roads"
	roads.Parent = parent

	local roadColor = Color3.fromRGB(48, 50, 53)
	local roadWidth = GameConfig.World.RoadWidth
	local mapSize = GameConfig.World.MapSize
	local surfaceY = GameConfig.World.DrivingSurfaceY
	local roadThickness = 0.05

	makePart({
		Name = "EastWestRoad",
		Size = Vector3.new(mapSize, roadThickness, roadWidth),
		Position = Vector3.new(0, surfaceY + roadThickness / 2, 0),
		Color = roadColor,
		Material = Enum.Material.Asphalt,
		CanCollide = false,
		CanQuery = false,
		Parent = roads,
	})
	makePart({
		Name = "NorthSouthRoad",
		Size = Vector3.new(roadWidth, roadThickness, mapSize),
		Position = Vector3.new(0, surfaceY + roadThickness / 2 + 0.002, 0),
		Color = roadColor,
		Material = Enum.Material.Asphalt,
		CanCollide = false,
		CanQuery = false,
		Parent = roads,
	})

	local markings = Instance.new("Folder")
	markings.Name = "LaneMarkings"
	markings.Parent = roads

	for offset = -232, 232, 24 do
		if math.abs(offset) > 28 then
			makePart({
				Name = "RoadStripe",
				Size = Vector3.new(10, 0.05, 0.6),
				Position = Vector3.new(offset, surfaceY + 0.03, 0),
				Color = Color3.fromRGB(255, 214, 74),
				Material = Enum.Material.Neon,
				CanCollide = false,
				CanQuery = false,
				Parent = markings,
			})
			makePart({
				Name = "RoadStripe",
				Size = Vector3.new(0.6, 0.05, 10),
				Position = Vector3.new(0, surfaceY + 0.03, offset),
				Color = Color3.fromRGB(255, 214, 74),
				Material = Enum.Material.Neon,
				CanCollide = false,
				CanQuery = false,
				Parent = markings,
			})
		end
	end
end

local function createCityBlocks(parent: Instance)
	local cityBlocks = Instance.new("Model")
	cityBlocks.Name = "CityBlocks"
	cityBlocks.Parent = parent

	local surfaceY = GameConfig.World.DrivingSurfaceY
	local blockCenters = {
		Vector3.new(-139, surfaceY - 0.5, -139),
		Vector3.new(139, surfaceY - 0.5, -139),
		Vector3.new(-139, surfaceY - 0.5, 139),
		Vector3.new(139, surfaceY - 0.5, 139),
	}

	for index, center in blockCenters do
		makePart({
			Name = `SidewalkBlock{index}`,
			Size = Vector3.new(222, 0.05, 222),
			Position = Vector3.new(center.X, surfaceY + 0.025, center.Z),
			Color = Color3.fromRGB(168, 168, 168),
			Material = Enum.Material.Concrete,
			CanCollide = false,
			CanQuery = false,
			Parent = cityBlocks,
		})
	end

	-- Simple background buildings make the blockout feel like a city while keeping
	-- important landmarks easy to identify.
	makeBuildingShell(cityBlocks, "BlueApartments", Vector3.new(-155, surfaceY, -150), Vector3.new(70, 44, 55), Color3.fromRGB(86, 126, 160), "APARTMENTS")
	makeBuildingShell(cityBlocks, "CommunityCenter", Vector3.new(150, surfaceY, 148), Vector3.new(78, 28, 60), Color3.fromRGB(207, 155, 83), "COMMUNITY")
end

local function createConvenienceStore(parent: Instance)
	local store = Instance.new("Model")
	store.Name = "ConvenienceStore"
	store.Parent = parent

	local origin = Vector3.new(130, GameConfig.World.DrivingSurfaceY, -132)
	local width = 70
	local depth = 54
	local height = 20
	local wallColor = Color3.fromRGB(246, 235, 187)

	makePart({ Name = "Floor", Size = Vector3.new(width, 0.05, depth), Position = origin + Vector3.new(0, 0.06, 0), Color = Color3.fromRGB(216, 207, 179), Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = store })
	makePart({ Name = "BackWall", Size = Vector3.new(width, height, 2), Position = origin + Vector3.new(0, height / 2, depth / 2), Color = wallColor, Material = Enum.Material.Brick, Parent = store })
	makePart({ Name = "LeftWall", Size = Vector3.new(2, height, depth), Position = origin + Vector3.new(-width / 2, height / 2, 0), Color = wallColor, Material = Enum.Material.Brick, Parent = store })
	makePart({ Name = "RightWall", Size = Vector3.new(2, height, depth), Position = origin + Vector3.new(width / 2, height / 2, 0), Color = wallColor, Material = Enum.Material.Brick, Parent = store })
	makePart({ Name = "FrontWallLeft", Size = Vector3.new(25, height, 2), Position = origin + Vector3.new(-22.5, height / 2, -depth / 2), Color = wallColor, Material = Enum.Material.Brick, Parent = store })
	makePart({ Name = "FrontWallRight", Size = Vector3.new(25, height, 2), Position = origin + Vector3.new(22.5, height / 2, -depth / 2), Color = wallColor, Material = Enum.Material.Brick, Parent = store })
	makePart({ Name = "Roof", Size = Vector3.new(width + 2, 1, depth + 2), Position = origin + Vector3.new(0, height, 0), Color = Color3.fromRGB(52, 131, 77), Material = Enum.Material.Metal, Parent = store })

	local sign = makePart({
		Name = "StoreSign",
		Size = Vector3.new(42, 7, 1),
		Position = origin + Vector3.new(0, 15, -(depth / 2 + 1)),
		Color = Color3.fromRGB(52, 151, 82),
		Material = Enum.Material.SmoothPlastic,
		Parent = store,
	})
	addSurfaceLabel(sign, "QUICK STOP", Enum.NormalId.Front)

	local counter = makePart({
		Name = "Counter",
		Size = Vector3.new(28, 5, 5),
		Position = origin + Vector3.new(14, 2.5, 17),
		Color = Color3.fromRGB(121, 76, 48),
		Material = Enum.Material.Wood,
		Parent = store,
	})
	local register = makePart({
		Name = "RobberyRegister",
		Size = Vector3.new(4, 3, 3),
		Position = counter.Position + Vector3.new(0, 4, 0),
		Color = Color3.fromRGB(48, 52, 58),
		Material = Enum.Material.Metal,
		Parent = store,
	})
	register:SetAttribute("RobberyEnabled", true)
	register:SetAttribute("RobberyStoreId", "QuickStop")

	local comingSoon = makePart({
		Name = "MilestoneSign",
		Size = Vector3.new(24, 5, 0.5),
		Position = origin + Vector3.new(0, 5, 26),
		Color = Color3.fromRGB(70, 70, 74),
		CanCollide = false,
		Parent = store,
	})
	addSurfaceLabel(comingSoon, "ROB THE REGISTER", Enum.NormalId.Front)
	store.PrimaryPart = counter
end

local function createPoliceStation(parent: Instance)
	local station = Instance.new("Model")
	station.Name = "PoliceStation"
	station.Parent = parent
	station:SetAttribute("ResponseOrigin", true)

	local surfaceY = GameConfig.World.DrivingSurfaceY
	local center = Vector3.new(-140, surfaceY, 135)
	local wallColor = Color3.fromRGB(157, 178, 203)
	local navy = Color3.fromRGB(34, 70, 125)
	local darkMetal = Color3.fromRGB(52, 60, 72)
	local glass = Color3.fromRGB(125, 205, 232)

	-- A single base collision plane remains underneath the city. This thin floor
	-- is visual-only so the stable vehicle suspension never sees another layer.
	makePart({ Name = "StationFloor", Size = Vector3.new(78, 0.05, 60), Position = center + Vector3.new(0, 0.025, 0), Color = Color3.fromRGB(185, 190, 197), Material = Enum.Material.Concrete, CanCollide = false, CanQuery = false, Parent = station })
	makePart({ Name = "BackWall", Size = Vector3.new(78, 22, 2), Position = center + Vector3.new(0, 11, 29), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })
	makePart({ Name = "RightWall", Size = Vector3.new(2, 22, 60), Position = center + Vector3.new(39, 11, 0), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })
	makePart({ Name = "LeftWall", Size = Vector3.new(2, 22, 60), Position = center + Vector3.new(-39, 11, 0), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })
	makePart({ Name = "Roof", Size = Vector3.new(82, 1, 64), Position = center + Vector3.new(0, 22.5, 0), Color = navy, Material = Enum.Material.Metal, Parent = station })
	makePart({ Name = "FrontHeader", Size = Vector3.new(78, 7, 2), Position = center + Vector3.new(0, 18.5, -29), Color = navy, Material = Enum.Material.Concrete, Parent = station })

	-- Lobby facade: real walk-through doors framed by blue glass windows.
	makePart({ Name = "LobbyEdgeLeft", Size = Vector3.new(4, 15, 2), Position = center + Vector3.new(-37, 7.5, -29), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })
	makePart({ Name = "LobbyWindowLeft", Size = Vector3.new(8, 11, 0.5), Position = center + Vector3.new(-31, 7, -30.1), Color = glass, Material = Enum.Material.Glass, Transparency = 0.25, Parent = station })
	local lobbyDoor = makePart({ Name = "LobbyDoors", Size = Vector3.new(8, 11, 0.35), Position = center + Vector3.new(-23, 7, -30.15), Color = glass, Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false, CanQuery = false, Parent = station })
	addSurfaceLabel(lobbyDoor, "ENTER", Enum.NormalId.Front)
	addSurfaceLabel(lobbyDoor, "EXIT", Enum.NormalId.Back)
	makePart({ Name = "LobbyWindowRight", Size = Vector3.new(8, 11, 0.5), Position = center + Vector3.new(-15, 7, -30.1), Color = glass, Material = Enum.Material.Glass, Transparency = 0.25, Parent = station })
	makePart({ Name = "LobbyEdgeRight", Size = Vector3.new(4, 15, 2), Position = center + Vector3.new(-9, 7.5, -29), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })

	local canopy = makePart({ Name = "EntranceCanopy", Size = Vector3.new(24, 1, 8), Position = center + Vector3.new(-23, 14, -33), Color = navy, Material = Enum.Material.Metal, Parent = station })
	makePart({ Name = "CanopyPostLeft", Size = Vector3.new(0.7, 13, 0.7), Position = center + Vector3.new(-34, 7, -36), Color = darkMetal, Material = Enum.Material.Metal, Parent = station })
	makePart({ Name = "CanopyPostRight", Size = Vector3.new(0.7, 13, 0.7), Position = center + Vector3.new(-12, 7, -36), Color = darkMetal, Material = Enum.Material.Metal, Parent = station })
	canopy:SetAttribute("LandmarkDetail", true)

	-- Two open garage bays with raised doors. Police units still spawn outside at
	-- response markers, so their tested physics lifecycle does not change.
	for index, bayX in { -135, -113 } do
		local localX = bayX - center.X
		makePart({ Name = `GaragePillar{index}`, Size = Vector3.new(2, 16, 2), Position = center + Vector3.new(localX - 10, 8, -29), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })
		local raisedDoor = makePart({ Name = `RaisedGarageDoor{index}`, Size = Vector3.new(18, 4, 0.5), Position = center + Vector3.new(localX, 14, -30.1), Color = darkMetal, Material = Enum.Material.Metal, CanCollide = false, Parent = station })
		addSurfaceLabel(raisedDoor, `UNIT {index}`, Enum.NormalId.Front)
		makePart({ Name = `GarageStripeLeft{index}`, Size = Vector3.new(0.35, 0.06, 52), Position = Vector3.new(bayX - 8, surfaceY + 0.06, 124), Color = Color3.fromRGB(245, 221, 94), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = station })
		makePart({ Name = `GarageStripeRight{index}`, Size = Vector3.new(0.35, 0.06, 52), Position = Vector3.new(bayX + 8, surfaceY + 0.06, 124), Color = Color3.fromRGB(245, 221, 94), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = station })
	end
	makePart({ Name = "GarageRightPillar", Size = Vector3.new(2, 16, 2), Position = center + Vector3.new(38, 8, -29), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })

	-- Lobby props make the building explorable without introducing another game
	-- system or requiring third-party models.
	makePart({ Name = "LobbyDivider", Size = Vector3.new(1, 16, 58), Position = center + Vector3.new(-7, 8, 0), Color = wallColor, Material = Enum.Material.Concrete, Parent = station })
	local desk = makePart({ Name = "FrontDesk", Size = Vector3.new(18, 4, 4), Position = center + Vector3.new(-23, 2.5, -3), Color = Color3.fromRGB(98, 68, 48), Material = Enum.Material.Wood, Parent = station })
	addSurfaceLabel(desk, "FRONT DESK", Enum.NormalId.Front)
	makePart({ Name = "LobbyBenchLeft", Size = Vector3.new(7, 1.2, 2), Position = center + Vector3.new(-33, 1.6, -8), Color = Color3.fromRGB(64, 83, 105), Material = Enum.Material.Wood, Parent = station })
	makePart({ Name = "LobbyBenchRight", Size = Vector3.new(7, 1.2, 2), Position = center + Vector3.new(-15, 1.6, -8), Color = Color3.fromRGB(64, 83, 105), Material = Enum.Material.Wood, Parent = station })

	local stationSign = makePart({ Name = "StationSign", Size = Vector3.new(26, 4.5, 0.6), Position = center + Vector3.new(-23, 19, -30.2), Color = Color3.fromRGB(235, 239, 245), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = station })
	addSurfaceLabel(stationSign, "POLICE", Enum.NormalId.Front)
	makePart({ Name = "SignLightRed", Size = Vector3.new(2.5, 0.6, 0.8), Position = center + Vector3.new(-38, 19, -30.3), Color = Color3.fromRGB(255, 65, 65), Material = Enum.Material.Neon, CanCollide = false, Parent = station })
	makePart({ Name = "SignLightBlue", Size = Vector3.new(2.5, 0.6, 0.8), Position = center + Vector3.new(-8, 19, -30.3), Color = Color3.fromRGB(65, 140, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = station })

	station.PrimaryPart = station:FindFirstChild("BackWall") :: BasePart
end

local function createJail(parent: Instance)
	local jail = Instance.new("Model")
	jail.Name = "Jail"
	jail.Parent = parent

	local surfaceY = GameConfig.World.DrivingSurfaceY
	local center = Vector3.new(-163, surfaceY, 153)
	local wallColor = Color3.fromRGB(105, 116, 132)
	local barColor = Color3.fromRGB(55, 62, 72)
	local cellWidth = 7.5
	local cellDepth = 20

	-- Four cells occupy the rear-left detention wing inside the station shell.
	makePart({ Name = "JailFloor", Size = Vector3.new(30, 0.05, cellDepth), Position = center + Vector3.new(0, 0.06, 0), Color = Color3.fromRGB(125, 132, 143), Material = Enum.Material.Concrete, CanCollide = false, CanQuery = false, Parent = jail })
	makePart({ Name = "BackWall", Size = Vector3.new(30, 8, 0.6), Position = center + Vector3.new(0, 4, cellDepth / 2), Color = wallColor, Material = Enum.Material.Concrete, Parent = jail })
	makePart({ Name = "CellCeiling", Size = Vector3.new(30, 0.6, cellDepth), Position = center + Vector3.new(0, 8.3, 0), Color = wallColor, Material = Enum.Material.Metal, Parent = jail })

	for dividerIndex = 0, 4 do
		local dividerX = -15 + dividerIndex * cellWidth
		makePart({ Name = `CellDivider{dividerIndex}`, Size = Vector3.new(0.45, 8, cellDepth), Position = center + Vector3.new(dividerX, 4, 0), Color = wallColor, Material = Enum.Material.Concrete, Parent = jail })
	end

	for cellIndex = 1, 4 do
		local cellX = -15 + (cellIndex - 0.5) * cellWidth
		for barIndex = 1, 7 do
			local barOffset = barIndex - 4
			makePart({ Name = `Cell{cellIndex}FrontBar{barIndex}`, Size = Vector3.new(0.3, 8, 0.3), Position = center + Vector3.new(cellX + barOffset, 4, -cellDepth / 2), Color = barColor, Material = Enum.Material.Metal, Parent = jail })
		end
		makePart({ Name = `Cell{cellIndex}CrossBarLow`, Size = Vector3.new(cellWidth, 0.3, 0.3), Position = center + Vector3.new(cellX, 2.5, -cellDepth / 2), Color = barColor, Material = Enum.Material.Metal, Parent = jail })
		makePart({ Name = `Cell{cellIndex}CrossBarHigh`, Size = Vector3.new(cellWidth, 0.3, 0.3), Position = center + Vector3.new(cellX, 6.2, -cellDepth / 2), Color = barColor, Material = Enum.Material.Metal, Parent = jail })

		local cellSign = makePart({ Name = `CellSign{cellIndex}`, Size = Vector3.new(5.8, 1.2, 0.4), Position = center + Vector3.new(cellX, 7.2, -(cellDepth / 2 + 0.25)), Color = Color3.fromRGB(35, 75, 135), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = jail })
		addSurfaceLabel(cellSign, `CELL {cellIndex}`, Enum.NormalId.Front)

		local cellSpawn = makePart({ Name = `CellSpawn{cellIndex}`, Size = Vector3.new(2, 0.2, 2), Position = center + Vector3.new(cellX, 0.6, 1), Transparency = 1, CanCollide = false, CanQuery = false, Parent = jail })
		cellSpawn:SetAttribute("SpawnType", "JailCell")
	end

	local sign = makePart({ Name = "JailSign", Size = Vector3.new(18, 2.5, 0.5), Position = center + Vector3.new(0, 10.2, -(cellDepth / 2 + 0.3)), Color = Color3.fromRGB(35, 75, 135), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = jail })
	addSurfaceLabel(sign, "HOLDING CELLS", Enum.NormalId.Front)

	local releaseSpawn = makePart({ Name = "ReleaseSpawn", Size = Vector3.new(3, 0.2, 3), Position = Vector3.new(-163, surfaceY + 0.6, 99), Transparency = 1, CanCollide = false, CanQuery = false, Parent = jail })
	releaseSpawn:SetAttribute("SpawnType", "PoliceRelease")
end

local function createSpawns(parent: Instance)
	local spawns = Instance.new("Folder")
	spawns.Name = "Spawns"
	spawns.Parent = parent

	local playerSpawn = Instance.new("SpawnLocation")
	playerSpawn.Name = "PlayerSpawn"
	playerSpawn.Anchored = true
	playerSpawn.Size = Vector3.new(12, 1, 12)
	playerSpawn.Position = Vector3.new(32, GameConfig.World.DrivingSurfaceY + 0.5, 32)
	playerSpawn.Color = Color3.fromRGB(73, 200, 92)
	playerSpawn.Material = Enum.Material.Neon
	playerSpawn.Neutral = true
	playerSpawn.Parent = spawns

	local vehicleSpawn = makePart({
		Name = "VehicleSpawn",
		Size = Vector3.new(12, 0.3, 22),
		Position = Vector3.new(52, GameConfig.World.DrivingSurfaceY + 0.15, 10),
		Color = Color3.fromRGB(69, 156, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = spawns,
	})
	addSurfaceLabel(vehicleSpawn, "CAR\nMILESTONE 2", Enum.NormalId.Top)

	local policeSpawns = Instance.new("Folder")
	policeSpawns.Name = "PoliceSpawns"
	policeSpawns.Parent = spawns

	for index, position in {
		Vector3.new(-135, GameConfig.World.DrivingSurfaceY, 94),
		Vector3.new(-113, GameConfig.World.DrivingSurfaceY, 94),
	} do
		local marker = makePart({
			Name = `StationResponse{index}`,
			Size = Vector3.new(4, 1, 4),
			Position = position,
			Color = Color3.fromRGB(30, 100, 230),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			Parent = policeSpawns,
		})
		marker:SetAttribute("SpawnType", "PoliceResponse")
	end
end

function WorldService.Start()
	local existing = Workspace:FindFirstChild(GameConfig.World.ContainerName)
	if existing then
		warn(`WorldService did not generate the map because Workspace.{GameConfig.World.ContainerName} already exists`)
		return
	end

	local world = Instance.new("Model")
	world.Name = GameConfig.World.ContainerName
	world:SetAttribute("GeneratedWorldVersion", GameConfig.WorldVersion)
	world.Parent = Workspace

	makePart({
		Name = "Ground",
		Size = Vector3.new(GameConfig.World.MapSize, 2, GameConfig.World.MapSize),
		-- One continuous collision plane keeps the arcade chassis stable. Roads,
		-- sidewalks, and floors are non-queryable visual skins just above it.
		Position = Vector3.new(0, GameConfig.World.DrivingSurfaceY - 1, 0),
		Color = Color3.fromRGB(83, 137, 71),
		Material = Enum.Material.Grass,
		Parent = world,
	})

	createRoads(world)
	createCityBlocks(world)

	local landmarks = Instance.new("Model")
	landmarks.Name = "Landmarks"
	landmarks.Parent = world
	createConvenienceStore(landmarks)
	createPoliceStation(landmarks)
	createJail(landmarks)
	createSpawns(world)

	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.35
end

return table.freeze(WorldService)
