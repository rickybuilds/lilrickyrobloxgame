--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CityConfig = require(ReplicatedStorage.Shared.Config.CityConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RobberyLocationConfig = require(ReplicatedStorage.Shared.Config.RobberyLocationConfig)
local SpawnConfig = require(ReplicatedStorage.Shared.Config.SpawnConfig)

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

local function makeCityBuilding(parent: Instance, definition: CityConfig.BuildingDefinition): Model
	local model = Instance.new("Model")
	model.Name = definition.Name
	model:SetAttribute("BuildingStyle", definition.Style)
	model.Parent = parent

	local surfaceY = GameConfig.World.DrivingSurfaceY
	local center = Vector3.new(definition.Position.X, surfaceY, definition.Position.Z)
	local size = definition.Size
	local building = makePart({
		Name = "Building",
		Size = size,
		Position = center + Vector3.new(0, size.Y / 2, 0),
		Color = definition.Color,
		Material = if definition.Style == "Warehouse" then Enum.Material.Metal else Enum.Material.Concrete,
		Parent = model,
	})

	makePart({
		Name = "RoofTrim",
		Size = Vector3.new(size.X + 2, 1.2, size.Z + 2),
		Position = center + Vector3.new(0, size.Y + 0.6, 0),
		Color = definition.AccentColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})

	local accent = makePart({
		Name = "FrontAccent",
		Size = Vector3.new(size.X - 4, 2.2, 0.6),
		Position = center + Vector3.new(0, size.Y * 0.68, -(size.Z / 2 + 0.35)),
		Color = definition.AccentColor,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		CanQuery = false,
		Parent = model,
	})
	accent:SetAttribute("CityDetail", true)

	local sign = makePart({
		Name = "BuildingSign",
		Size = Vector3.new(math.min(size.X - 8, 34), 4.5, 0.7),
		Position = center + Vector3.new(0, size.Y * 0.82, -(size.Z / 2 + 0.55)),
		Color = Color3.fromRGB(35, 48, 67),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = model,
	})
	addSurfaceLabel(sign, definition.DisplayName, Enum.NormalId.Front)

	local windowCount = math.clamp(math.floor(size.X / 16), 3, 6)
	local windowSpacing = (size.X - 14) / math.max(1, windowCount - 1)
	for windowIndex = 1, windowCount do
		local x = -((size.X - 14) / 2) + (windowIndex - 1) * windowSpacing
		makePart({
			Name = `FrontWindow{windowIndex}`,
			Size = Vector3.new(7, math.clamp(size.Y * 0.22, 4, 9), 0.35),
			Position = center + Vector3.new(x, size.Y * 0.38, -(size.Z / 2 + 0.25)),
			Color = Color3.fromRGB(117, 196, 220),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
			CanCollide = false,
			CanQuery = false,
			Parent = model,
		})
	end

	if definition.Style == "Warehouse" then
		makePart({
			Name = "LoadingDoor",
			Size = Vector3.new(math.min(24, size.X - 12), 10, 0.5),
			Position = center + Vector3.new(0, 5, -(size.Z / 2 + 0.4)),
			Color = Color3.fromRGB(65, 70, 76),
			Material = Enum.Material.Metal,
			CanCollide = false,
			Parent = model,
		})
	elseif definition.Style == "Storefront" then
		makePart({
			Name = "Awning",
			Size = Vector3.new(math.min(42, size.X - 8), 1, 6),
			Position = center + Vector3.new(0, 8, -(size.Z / 2 + 3)),
			Color = definition.AccentColor,
			Material = Enum.Material.Fabric,
			CanCollide = false,
			CanQuery = false,
			Parent = model,
		})
	end

	model.PrimaryPart = building
	return model
end

local function makeParkedCar(parent: Instance, name: string, position: Vector3, color: Color3)
	local car = Instance.new("Model")
	car.Name = name
	car:SetAttribute("ParkedProp", true)
	car.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY
	local base = makePart({
		Name = "Body",
		Size = Vector3.new(6, 2, 11),
		Position = Vector3.new(position.X, surfaceY + 1.1, position.Z),
		Color = color,
		Material = Enum.Material.Metal,
		Parent = car,
	})
	makePart({
		Name = "Cabin",
		Size = Vector3.new(5, 2, 5.5),
		Position = Vector3.new(position.X, surfaceY + 2.8, position.Z + 0.5),
		Color = Color3.fromRGB(104, 164, 184),
		Material = Enum.Material.Glass,
		Parent = car,
	})
	for wheelIndex, offset in {
		Vector3.new(-3.1, 0.9, -3.4),
		Vector3.new(3.1, 0.9, -3.4),
		Vector3.new(-3.1, 0.9, 3.4),
		Vector3.new(3.1, 0.9, 3.4),
	} do
		makePart({
			Name = `Wheel{wheelIndex}`,
			Size = Vector3.new(0.8, 1.8, 2),
			Position = Vector3.new(position.X, surfaceY, position.Z) + offset,
			Color = Color3.fromRGB(28, 30, 34),
			Material = Enum.Material.Rubber,
			Parent = car,
		})
	end
	car.PrimaryPart = base
end

local satellitePrecincts = {
	{ Id = "North", DisplayName = "NORTH PRECINCT", Position = Vector3.new(-136, 0, -503), ResponsePosition = Vector3.new(-136, 0, -426), MarkerAxis = "X", Color = Color3.fromRGB(74, 112, 158) },
	{ Id = "East", DisplayName = "EAST PRECINCT", Position = Vector3.new(657, 0, -136), ResponsePosition = Vector3.new(580, 0, -136), MarkerAxis = "Z", Color = Color3.fromRGB(65, 126, 164) },
	{ Id = "South", DisplayName = "SOUTH PRECINCT", Position = Vector3.new(-136, 0, 503), ResponsePosition = Vector3.new(-136, 0, 426), MarkerAxis = "X", Color = Color3.fromRGB(83, 105, 156) },
	{ Id = "West", DisplayName = "WEST PRECINCT", Position = Vector3.new(-503, 0, 349), ResponsePosition = Vector3.new(-426, 0, 349), MarkerAxis = "Z", Color = Color3.fromRGB(61, 118, 151) },
	{ Id = "Southeast", DisplayName = "SOUTHEAST PRECINCT", Position = Vector3.new(657, 0, 657), ResponsePosition = Vector3.new(657, 0, 580), MarkerAxis = "X", Color = Color3.fromRGB(77, 104, 145) },
}

local function isSatellitePrecinctBlock(rowCenter: number, columnCenter: number): boolean
	for _, precinct in satellitePrecincts do
		if precinct.Position.X == columnCenter and precinct.Position.Z == rowCenter then
			return true
		end
	end
	return false
end

local function createParkingGarage(parent: Instance, center: Vector3)
	local garage = Instance.new("Model")
	garage.Name = "WestParkingGarage"
	garage.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY
	local concrete = Color3.fromRGB(105, 115, 126)
	local yellow = Color3.fromRGB(242, 197, 75)

	makePart({ Name = "GroundSkin", Size = Vector3.new(80, 0.05, 80), Position = Vector3.new(center.X, surfaceY + 0.08, center.Z), Color = Color3.fromRGB(66, 68, 72), Material = Enum.Material.Asphalt, CanCollide = false, CanQuery = false, Parent = garage })
	for pillarIndex, offset in {
		Vector3.new(-35, 5.5, -35), Vector3.new(0, 5.5, -35), Vector3.new(35, 5.5, -35),
		Vector3.new(-35, 5.5, 0), Vector3.new(35, 5.5, 0),
		Vector3.new(-35, 5.5, 35), Vector3.new(0, 5.5, 35), Vector3.new(35, 5.5, 35),
	} do
		makePart({ Name = `Pillar{pillarIndex}`, Size = Vector3.new(3, 11, 3), Position = Vector3.new(center.X, surfaceY, center.Z) + offset, Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	end
	makePart({ Name = "SecondDeck", Size = Vector3.new(80, 1, 80), Position = Vector3.new(center.X, surfaceY + 11.5, center.Z), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "RoofDeck", Size = Vector3.new(82, 1, 82), Position = Vector3.new(center.X, surfaceY + 23, center.Z), Color = Color3.fromRGB(75, 84, 96), Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "BackWall", Size = Vector3.new(80, 11, 2), Position = Vector3.new(center.X, surfaceY + 5.5, center.Z + 39), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "GroundLeftWall", Size = Vector3.new(2, 11, 30), Position = Vector3.new(center.X - 39, surfaceY + 5.5, center.Z + 24), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "GroundRightWall", Size = Vector3.new(2, 11, 30), Position = Vector3.new(center.X + 39, surfaceY + 5.5, center.Z + 24), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })

	-- The ground floor remains open for driving, while the upper floor uses a
	-- complete opaque shell so the garage looks intentional from every angle.
	makePart({ Name = "UpperFrontWall", Size = Vector3.new(80, 10, 2), Position = Vector3.new(center.X, surfaceY + 17.5, center.Z - 39), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "UpperBackWall", Size = Vector3.new(80, 10, 2), Position = Vector3.new(center.X, surfaceY + 17.5, center.Z + 39), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "UpperLeftWall", Size = Vector3.new(2, 10, 80), Position = Vector3.new(center.X - 39, surfaceY + 17.5, center.Z), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "UpperRightWall", Size = Vector3.new(2, 10, 80), Position = Vector3.new(center.X + 39, surfaceY + 17.5, center.Z), Color = concrete, Material = Enum.Material.Concrete, Parent = garage })
	makePart({ Name = "UpperFrontStripe", Size = Vector3.new(78, 1.2, 0.5), Position = Vector3.new(center.X, surfaceY + 14.5, center.Z - 40.1), Color = yellow, Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = garage })
	makePart({ Name = "UpperBackStripe", Size = Vector3.new(78, 1.2, 0.5), Position = Vector3.new(center.X, surfaceY + 14.5, center.Z + 40.1), Color = yellow, Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = garage })
	local sign = makePart({ Name = "GarageSign", Size = Vector3.new(40, 5, 0.8), Position = Vector3.new(center.X, surfaceY + 18, center.Z - 40.5), Color = Color3.fromRGB(35, 48, 67), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = garage })
	addSurfaceLabel(sign, "WEST PARKING", Enum.NormalId.Front)
	for lightIndex, xOffset in { -24, 0, 24 } do
		makePart({ Name = `CeilingLight{lightIndex}`, Size = Vector3.new(12, 0.25, 2), Position = Vector3.new(center.X + xOffset, surfaceY + 10.85, center.Z - 2), Color = Color3.fromRGB(255, 239, 180), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = garage })
	end

	makeParkedCar(garage, "ParkedCar1", Vector3.new(center.X - 22, 0, center.Z + 13), Color3.fromRGB(209, 86, 73))
	makeParkedCar(garage, "ParkedCar2", Vector3.new(center.X, 0, center.Z + 13), Color3.fromRGB(78, 128, 190))
	makeParkedCar(garage, "ParkedCar3", Vector3.new(center.X + 22, 0, center.Z + 13), Color3.fromRGB(220, 191, 78))
end

local function createInfillBuildings(parent: Instance)
	local positions = {
		Vector3.new(-45, 0, -218), Vector3.new(-45, 0, -158), Vector3.new(-45, 0, -105),
		Vector3.new(45, 0, -218), Vector3.new(45, 0, -158), Vector3.new(45, 0, -105),
		Vector3.new(-45, 0, 105), Vector3.new(-45, 0, 158), Vector3.new(-45, 0, 218),
		Vector3.new(45, 0, 105), Vector3.new(45, 0, 158), Vector3.new(45, 0, 218),
		Vector3.new(-218, 0, -45), Vector3.new(-158, 0, -45), Vector3.new(-105, 0, -45),
		Vector3.new(105, 0, -45), Vector3.new(158, 0, -45), Vector3.new(218, 0, -45),
		Vector3.new(-218, 0, 45), Vector3.new(-158, 0, 45), Vector3.new(-105, 0, 45),
		Vector3.new(105, 0, 45), Vector3.new(158, 0, 45), Vector3.new(218, 0, 45),
	}
	local displayNames = {
		"TOY BOX", "BUBBLE TEA", "CITY PIZZA", "PET SHOP", "COMIC CLUB", "BAKERY",
		"MUSIC SHOP", "ICE CREAM", "FLOWERS", "SPORTS", "NOODLES", "GAME SHOP",
		"BOOK NOOK", "HOBBY SHOP", "JUICE BAR", "DANCE STUDIO", "ROBOT LAB", "CANDY SHOP",
		"BIKE SHOP", "ART SUPPLY", "TACO TIME", "MOVIE CLUB", "SKATE SHOP", "CITY CLINIC",
	}
	local colors = {
		Color3.fromRGB(186, 102, 87), Color3.fromRGB(81, 137, 167),
		Color3.fromRGB(111, 91, 157), Color3.fromRGB(181, 143, 68),
		Color3.fromRGB(75, 148, 116), Color3.fromRGB(154, 105, 137),
	}
	local accents = {
		Color3.fromRGB(252, 211, 91), Color3.fromRGB(96, 229, 218),
		Color3.fromRGB(245, 125, 161), Color3.fromRGB(239, 239, 230),
	}

	for buildingIndex, position in positions do
		local verticalRow = math.abs(position.X) == 45
		local definition: CityConfig.BuildingDefinition = {
			Name = `CityInfill{buildingIndex}`,
			DisplayName = displayNames[buildingIndex],
			Position = position,
			Size = if verticalRow
				then Vector3.new(30, 17 + (buildingIndex % 4) * 5, 40)
				else Vector3.new(40, 17 + (buildingIndex % 4) * 5, 30),
			Color = colors[((buildingIndex - 1) % #colors) + 1],
			AccentColor = accents[((buildingIndex - 1) % #accents) + 1],
			Style = if buildingIndex % 5 == 0 then "Tower" else "Storefront",
		}
		makeCityBuilding(parent, definition)
	end
end

local function createMegaCityBuildings(parent: Instance)
	local districtNames = {
		"CITY LOFTS", "STAR HOTEL", "METRO MARKET", "SKYLINE", "TECH HUB", "COFFEE HOUSE",
		"FASHION", "FITNESS CLUB", "PHARMACY", "BRICKWORKS", "CLOUD NINE", "TOWN MARKET",
		"DESIGN STUDIO", "CITY OFFICES", "SUNSET SUITES", "ROOFTOP CLUB",
	}
	local colors = {
		Color3.fromRGB(87, 113, 142), Color3.fromRGB(157, 91, 83),
		Color3.fromRGB(94, 142, 104), Color3.fromRGB(136, 105, 154),
		Color3.fromRGB(169, 133, 72), Color3.fromRGB(83, 139, 147),
		Color3.fromRGB(133, 119, 103), Color3.fromRGB(103, 119, 161),
	}
	local accents = {
		Color3.fromRGB(245, 203, 84), Color3.fromRGB(102, 226, 216),
		Color3.fromRGB(243, 127, 153), Color3.fromRGB(226, 232, 239),
		Color3.fromRGB(119, 185, 246), Color3.fromRGB(245, 164, 89),
	}
	local buildingIndex = 0

	for _, row in CityConfig.BlockCoordinates do
		for _, column in CityConfig.BlockCoordinates do
			if (math.abs(row.Center) >= 500 or math.abs(column.Center) >= 500)
				and not isSatellitePrecinctBlock(row.Center, column.Center)
			then
				local splitAlongX = column.Size >= row.Size
				for lotIndex = 1, 2 do
					buildingIndex += 1
					local direction = if lotIndex == 1 then -1 else 1
					local position = Vector3.new(
						column.Center + (if splitAlongX then direction * column.Size * 0.23 else 0),
						0,
						row.Center + (if splitAlongX then 0 else direction * row.Size * 0.23)
					)
					local width = if splitAlongX then math.min(70, column.Size * 0.36) else math.min(72, column.Size * 0.68)
					local depth = if splitAlongX then math.min(72, row.Size * 0.68) else math.min(70, row.Size * 0.36)
					local style: CityConfig.BuildingStyle = if buildingIndex % 4 == 0
						then "Tower"
						elseif buildingIndex % 3 == 0 then "Residential"
						elseif buildingIndex % 5 == 0 then "Warehouse"
						else "Storefront"
					local definition: CityConfig.BuildingDefinition = {
						Name = `MegaCityBuilding{buildingIndex}`,
						DisplayName = districtNames[((buildingIndex - 1) % #districtNames) + 1],
						Position = position,
						Size = Vector3.new(width, 20 + (buildingIndex % 7) * 7, depth),
						Color = colors[((buildingIndex - 1) % #colors) + 1],
						AccentColor = accents[((buildingIndex - 1) % #accents) + 1],
						Style = style,
					}
					makeCityBuilding(parent, definition)
				end
			end
		end
	end
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

	local markings = Instance.new("Folder")
	markings.Name = "LaneMarkings"
	markings.Parent = roads

	for roadIndex, roadCenter in CityConfig.RoadCenters do
		makePart({
			Name = if roadCenter == 0 then "EastWestRoad" else `EastWestRoad{roadIndex}`,
			Size = Vector3.new(mapSize, roadThickness, roadWidth),
			Position = Vector3.new(0, surfaceY + roadThickness / 2, roadCenter),
			Color = roadColor,
			Material = Enum.Material.Asphalt,
			CanCollide = false,
			CanQuery = false,
			Parent = roads,
		})
		makePart({
			Name = if roadCenter == 0 then "NorthSouthRoad" else `NorthSouthRoad{roadIndex}`,
			Size = Vector3.new(roadWidth, roadThickness, mapSize),
			Position = Vector3.new(roadCenter, surfaceY + roadThickness / 2 + 0.002, 0),
			Color = roadColor,
			Material = Enum.Material.Asphalt,
			CanCollide = false,
			CanQuery = false,
			Parent = roads,
		})
	end

	local mapHalf = mapSize / 2
	for offset = -mapHalf + 12, mapHalf - 12, 24 do
		local stripeIndex = math.floor((offset + mapHalf) / 24) + 1
		local insideIntersection = false
		for _, crossingCenter in CityConfig.RoadCenters do
			if math.abs(offset - crossingCenter) <= roadWidth / 2 + 10 then
				insideIntersection = true
				break
			end
		end
		if not insideIntersection then
			for roadIndex, roadCenter in CityConfig.RoadCenters do
			makePart({
				Name = `EastWestStripe{roadIndex}_{stripeIndex}`,
				Size = Vector3.new(10, 0.05, 0.6),
				Position = Vector3.new(offset, surfaceY + 0.055, roadCenter),
				Color = Color3.fromRGB(255, 214, 74),
				Material = Enum.Material.Neon,
				CanCollide = false,
				CanQuery = false,
				Parent = markings,
			})
			makePart({
				Name = `NorthSouthStripe{roadIndex}_{stripeIndex}`,
				Size = Vector3.new(0.6, 0.05, 10),
				Position = Vector3.new(roadCenter, surfaceY + 0.058, offset),
				Color = Color3.fromRGB(255, 214, 74),
				Material = Enum.Material.Neon,
				CanCollide = false,
				CanQuery = false,
				Parent = markings,
			})
			end
		end
	end
end

local function createCityBlocks(parent: Instance)
	local cityBlocks = Instance.new("Model")
	cityBlocks.Name = "CityBlocks"
	cityBlocks.Parent = parent

	local surfaceY = GameConfig.World.DrivingSurfaceY
	for rowIndex, row in CityConfig.BlockCoordinates do
		for columnIndex, column in CityConfig.BlockCoordinates do
		makePart({
			Name = `SidewalkBlock{rowIndex}_{columnIndex}`,
			Size = Vector3.new(column.Size, 0.05, row.Size),
			Position = Vector3.new(column.Center, surfaceY + 0.025, row.Center),
			Color = Color3.fromRGB(168, 168, 168),
			Material = Enum.Material.Concrete,
			CanCollide = false,
			CanQuery = false,
			Parent = cityBlocks,
		})
		end
	end

	for _, definition in CityConfig.Buildings do
		if definition.Name == "WestParkingGarage" then
			createParkingGarage(cityBlocks, Vector3.new(definition.Position.X, surfaceY, definition.Position.Z))
		else
			makeCityBuilding(cityBlocks, definition)
		end
	end
	createInfillBuildings(cityBlocks)
	createMegaCityBuildings(cityBlocks)

	-- The original landmarks remain at their tested positions inside the expanded grid.
	makeBuildingShell(cityBlocks, "BlueApartments", Vector3.new(-155, surfaceY, -150), Vector3.new(70, 44, 55), Color3.fromRGB(86, 126, 160), "APARTMENTS")
	makeBuildingShell(cityBlocks, "CommunityCenter", Vector3.new(150, surfaceY, 148), Vector3.new(78, 28, 60), Color3.fromRGB(207, 155, 83), "COMMUNITY")
end

local function createParkingLot(
	parent: Instance,
	name: string,
	center: Vector3,
	size: Vector3,
	parkedCarCount: number
)
	local lot = Instance.new("Model")
	lot.Name = name
	lot.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY
	makePart({ Name = "Asphalt", Size = Vector3.new(size.X, 0.05, size.Z), Position = Vector3.new(center.X, surfaceY + 0.08, center.Z), Color = Color3.fromRGB(61, 63, 67), Material = Enum.Material.Asphalt, CanCollide = false, CanQuery = false, Parent = lot })

	local spaceWidth = size.X / (parkedCarCount + 1)
	for spaceIndex = 1, parkedCarCount do
		local x = center.X - size.X / 2 + spaceIndex * spaceWidth
		makePart({ Name = `ParkingLine{spaceIndex}`, Size = Vector3.new(0.25, 0.04, 18), Position = Vector3.new(x - 5, surfaceY + 0.12, center.Z), Color = Color3.fromRGB(235, 235, 220), Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = lot })
		makeParkedCar(
			lot,
			`ParkedCar{spaceIndex}`,
			Vector3.new(x, 0, center.Z),
			({
				Color3.fromRGB(196, 79, 68),
				Color3.fromRGB(78, 125, 184),
				Color3.fromRGB(221, 183, 67),
				Color3.fromRGB(115, 168, 102),
			})[((spaceIndex - 1) % 4) + 1]
		)
	end
end

local function makeTree(parent: Instance, name: string, position: Vector3)
	local surfaceY = GameConfig.World.DrivingSurfaceY
	makePart({ Name = `{name}Trunk`, Size = Vector3.new(1.6, 7, 1.6), Position = Vector3.new(position.X, surfaceY + 3.5, position.Z), Color = Color3.fromRGB(105, 73, 43), Material = Enum.Material.Wood, CanCollide = false, CanQuery = false, Parent = parent })
	local canopy = makePart({ Name = `{name}Canopy`, Size = Vector3.new(9, 9, 9), Position = Vector3.new(position.X, surfaceY + 9, position.Z), Color = Color3.fromRGB(62, 142, 77), Material = Enum.Material.Grass, CanCollide = false, CanQuery = false, Parent = parent })
	canopy.Shape = Enum.PartType.Ball
end

local function createCityDetails(parent: Instance)
	local details = Instance.new("Model")
	details.Name = "CityDetails"
	details.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY

	local alleys = Instance.new("Model")
	alleys.Name = "Alleys"
	alleys.Parent = details
	for alleyIndex, alley in {
		{ Center = Vector3.new(-136, surfaceY, -75), Size = Vector3.new(220, 0.04, CityConfig.AlleyWidth) },
		{ Center = Vector3.new(136, surfaceY, -75), Size = Vector3.new(220, 0.04, CityConfig.AlleyWidth) },
		{ Center = Vector3.new(-136, surfaceY, 75), Size = Vector3.new(220, 0.04, CityConfig.AlleyWidth) },
		{ Center = Vector3.new(136, surfaceY, 75), Size = Vector3.new(220, 0.04, CityConfig.AlleyWidth) },
		{ Center = Vector3.new(-75, surfaceY, -136), Size = Vector3.new(CityConfig.AlleyWidth, 0.04, 220) },
		{ Center = Vector3.new(75, surfaceY, -136), Size = Vector3.new(CityConfig.AlleyWidth, 0.04, 220) },
		{ Center = Vector3.new(-75, surfaceY, 136), Size = Vector3.new(CityConfig.AlleyWidth, 0.04, 220) },
		{ Center = Vector3.new(75, surfaceY, 136), Size = Vector3.new(CityConfig.AlleyWidth, 0.04, 220) },
	} do
		local alleyPart = makePart({ Name = `Alley{alleyIndex}`, Size = alley.Size, Position = alley.Center + Vector3.new(0, 0.09, 0), Color = Color3.fromRGB(72, 73, 75), Material = Enum.Material.Asphalt, CanCollide = false, CanQuery = false, Parent = alleys })
		alleyPart:SetAttribute("AlleyRoute", true)
	end

	local parking = Instance.new("Model")
	parking.Name = "ParkingAreas"
	parking.Parent = details
	createParkingLot(parking, "QuickStopParking", Vector3.new(130, surfaceY, -210), Vector3.new(96, 0, 48), 3)
	createParkingLot(parking, "CommunityParking", Vector3.new(132, surfaceY, 218), Vector3.new(86, 0, 42), 2)

	local pocketPark = Instance.new("Model")
	pocketPark.Name = "PocketPark"
	pocketPark.Parent = details
	makePart({ Name = "ParkGrass", Size = Vector3.new(36, 0.05, 52), Position = Vector3.new(43, surfaceY + 0.08, -210), Color = Color3.fromRGB(81, 151, 77), Material = Enum.Material.Grass, CanCollide = false, CanQuery = false, Parent = pocketPark })
	for treeIndex, treePosition in {
		Vector3.new(34, 0, -226), Vector3.new(52, 0, -226),
		Vector3.new(34, 0, -194), Vector3.new(52, 0, -194),
	} do
		makeTree(pocketPark, `ParkTree{treeIndex}`, treePosition)
	end
	makePart({ Name = "ParkBench1", Size = Vector3.new(7, 1.2, 2), Position = Vector3.new(43, surfaceY + 1.2, -218), Color = Color3.fromRGB(112, 77, 48), Material = Enum.Material.Wood, CanCollide = false, CanQuery = false, Parent = pocketPark })
	makePart({ Name = "ParkBench2", Size = Vector3.new(7, 1.2, 2), Position = Vector3.new(43, surfaceY + 1.2, -202), Color = Color3.fromRGB(112, 77, 48), Material = Enum.Material.Wood, CanCollide = false, CanQuery = false, Parent = pocketPark })

	local perimeterTrees = Instance.new("Model")
	perimeterTrees.Name = "CityTreeBelts"
	perimeterTrees.Parent = details
	local perimeterTreeIndex = 0
	local mapHalf = GameConfig.World.MapSize / 2
	local outerTreeLine = mapHalf - 22
	local outerRoadCenter = CityConfig.RoadCenters[#CityConfig.RoadCenters]
	local boulevardTreeLine = outerRoadCenter - GameConfig.World.RoadWidth / 2 - 8
	for coordinate = -mapHalf + 60, mapHalf - 60, 32 do
		local nearRoad = false
		for _, roadCenter in CityConfig.RoadCenters do
			if math.abs(coordinate - roadCenter) <= GameConfig.World.RoadWidth / 2 + 8 then
				nearRoad = true
				break
			end
		end
		if not nearRoad then
			for _, treePosition in {
				Vector3.new(-outerTreeLine, 0, coordinate), Vector3.new(outerTreeLine, 0, coordinate),
				Vector3.new(coordinate, 0, -outerTreeLine), Vector3.new(coordinate, 0, outerTreeLine),
				Vector3.new(-boulevardTreeLine, 0, coordinate), Vector3.new(boulevardTreeLine, 0, coordinate),
				Vector3.new(coordinate, 0, -boulevardTreeLine), Vector3.new(coordinate, 0, boulevardTreeLine),
			} do
				perimeterTreeIndex += 1
				makeTree(perimeterTrees, `CityTree{perimeterTreeIndex}`, treePosition)
			end
		end
	end

	local alleyProps = Instance.new("Model")
	alleyProps.Name = "AlleyProps"
	alleyProps.Parent = details
	for dumpsterIndex, position in {
		Vector3.new(-87, surfaceY + 2, -104),
		Vector3.new(87, surfaceY + 2, -180),
		Vector3.new(-87, surfaceY + 2, 186),
		Vector3.new(87, surfaceY + 2, 108),
	} do
		local dumpster = makePart({ Name = `Dumpster{dumpsterIndex}`, Size = Vector3.new(8, 4, 4), Position = position, Color = Color3.fromRGB(45, 105, 72), Material = Enum.Material.Metal, Parent = alleyProps })
		dumpster:SetAttribute("SightCover", true)
	end

	local streetLights = Instance.new("Model")
	streetLights.Name = "StreetLights"
	streetLights.Parent = details
	local lightIndex = 0
	for rowIndex, z in CityConfig.RoadCenters do
		for columnIndex, x in CityConfig.RoadCenters do
			lightIndex += 1
			local sign = if (rowIndex + columnIndex) % 2 == 0 then 1 else -1
			local lightPosition = Vector3.new(x + sign * 27, surfaceY, z + sign * 27)
			makePart({ Name = `StreetLightPost{lightIndex}`, Size = Vector3.new(0.6, 12, 0.6), Position = lightPosition + Vector3.new(0, 6, 0), Color = Color3.fromRGB(54, 59, 66), Material = Enum.Material.Metal, CanCollide = false, CanQuery = false, Parent = streetLights })
			makePart({ Name = `StreetLightLamp{lightIndex}`, Size = Vector3.new(3, 0.7, 3), Position = lightPosition + Vector3.new(0, 12.2, 0), Color = Color3.fromRGB(255, 237, 170), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = streetLights })
		end
	end
end

local function createRoadNetwork(parent: Instance)
	local network = Instance.new("Folder")
	network.Name = "RoadNetwork"
	network:SetAttribute("FutureNpcNavigation", true)
	network.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY
	local nodeCount = #CityConfig.RoadCenters

	for rowIndex, z in CityConfig.RoadCenters do
		for columnIndex, x in CityConfig.RoadCenters do
			local nodeName = `RoadNode_{rowIndex}_{columnIndex}`
			local node = makePart({ Name = nodeName, Size = Vector3.new(1, 1, 1), Position = Vector3.new(x, surfaceY + 0.5, z), Transparency = 1, CanCollide = false, CanQuery = false, Parent = network })
			node:SetAttribute("RoadNode", true)
			node:SetAttribute("Row", rowIndex)
			node:SetAttribute("Column", columnIndex)
			if rowIndex > 1 then node:SetAttribute("North", `RoadNode_{rowIndex - 1}_{columnIndex}`) end
			if rowIndex < nodeCount then node:SetAttribute("South", `RoadNode_{rowIndex + 1}_{columnIndex}`) end
			if columnIndex > 1 then node:SetAttribute("West", `RoadNode_{rowIndex}_{columnIndex - 1}`) end
			if columnIndex < nodeCount then node:SetAttribute("East", `RoadNode_{rowIndex}_{columnIndex + 1}`) end
		end
	end
end

local function createBoundary(parent: Instance)
	local boundary = Instance.new("Model")
	boundary.Name = "CityBoundary"
	boundary.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY
	local half = GameConfig.World.MapSize / 2 - CityConfig.BoundaryInset
	local length = GameConfig.World.MapSize - CityConfig.BoundaryInset * 2
	local color = Color3.fromRGB(67, 73, 82)
	makePart({ Name = "NorthGuardrail", Size = Vector3.new(length, 3, 2), Position = Vector3.new(0, surfaceY + 1.5, -half), Color = color, Material = Enum.Material.Metal, Parent = boundary })
	makePart({ Name = "SouthGuardrail", Size = Vector3.new(length, 3, 2), Position = Vector3.new(0, surfaceY + 1.5, half), Color = color, Material = Enum.Material.Metal, Parent = boundary })
	makePart({ Name = "WestGuardrail", Size = Vector3.new(2, 3, length), Position = Vector3.new(-half, surfaceY + 1.5, 0), Color = color, Material = Enum.Material.Metal, Parent = boundary })
	makePart({ Name = "EastGuardrail", Size = Vector3.new(2, 3, length), Position = Vector3.new(half, surfaceY + 1.5, 0), Color = color, Material = Enum.Material.Metal, Parent = boundary })
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

local function createRobberyLocation(
	parent: Instance,
	definition: RobberyLocationConfig.LocationDefinition,
	origin: Vector3,
	frontDirection: number
)
	local location = Instance.new("Model")
	location.Name = `Robbery_{definition.Id}`
	location:SetAttribute("RobberyTier", definition.Tier)
	location:SetAttribute("LocationVariant", definition.Variant)
	location:SetAttribute("RewardPreview", definition.Reward)
	location.Parent = parent

	local width = if definition.Variant == "Kiosk" then 22 elseif definition.Variant == "Industrial" then 32 else 28
	local depth = if definition.Variant == "Kiosk" then 16 else 20
	local height = if definition.Variant == "Industrial" then 11 else 10
	local frontFace = if frontDirection < 0 then Enum.NormalId.Front else Enum.NormalId.Back
	local wallMaterial = if definition.Variant == "Industrial" or definition.Variant == "Vault"
		then Enum.Material.Metal
		else Enum.Material.Concrete

	makePart({
		Name = "Floor",
		Size = Vector3.new(width, 0.05, depth),
		Position = origin + Vector3.new(0, 0.08, 0),
		Color = Color3.fromRGB(116, 120, 126),
		Material = Enum.Material.Concrete,
		CanCollide = false,
		CanQuery = false,
		Parent = location,
	})
	makePart({
		Name = "BackWall",
		Size = Vector3.new(width, height, 1),
		Position = origin + Vector3.new(0, height / 2, -frontDirection * (depth / 2 - 0.5)),
		Color = definition.Color,
		Material = wallMaterial,
		Parent = location,
	})
	for sideIndex, x in { -width / 2 + 0.5, width / 2 - 0.5 } do
		makePart({
			Name = `SideWall{sideIndex}`,
			Size = Vector3.new(1, height, depth),
			Position = origin + Vector3.new(x, height / 2, 0),
			Color = definition.Color,
			Material = wallMaterial,
			Parent = location,
		})
	end
	makePart({
		Name = "Roof",
		Size = Vector3.new(width + 1, 0.8, depth + 1),
		Position = origin + Vector3.new(0, height + 0.4, 0),
		Color = definition.AccentColor,
		Material = if definition.Variant == "Arcade" then Enum.Material.Neon else Enum.Material.Metal,
		Parent = location,
	})

	local sign = makePart({
		Name = "LocationSign",
		Size = Vector3.new(width - 3, 3.6, 0.6),
		Position = origin + Vector3.new(0, height - 1.8, frontDirection * (depth / 2 + 0.35)),
		Color = Color3.fromRGB(28, 36, 49),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = location,
	})
	addSurfaceLabel(sign, definition.DisplayName, frontFace)

	local tierStrip = makePart({
		Name = "TierStrip",
		Size = Vector3.new(width - 6, 1.2, 0.7),
		Position = origin + Vector3.new(0, height - 4.4, frontDirection * (depth / 2 + 0.4)),
		Color = definition.AccentColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CanQuery = false,
		Parent = location,
	})
	addSurfaceLabel(tierStrip, `TIER {definition.Tier}  ${definition.Reward}`, frontFace)

	local targetSize = if definition.Variant == "Arcade"
		then Vector3.new(5, 7, 4)
		elseif definition.Variant == "Industrial" then Vector3.new(8, 5, 4)
		elseif definition.Variant == "Vault" then Vector3.new(7, 6, 3)
		else Vector3.new(5, 3, 3)
	local targetHeight = if definition.Variant == "Storefront" or definition.Variant == "Kiosk"
		then 5
		else targetSize.Y / 2 + 0.5
	local targetPosition = origin
		+ Vector3.new(0, targetHeight, -frontDirection * (depth / 2 - 3))

	if definition.Variant == "Storefront" or definition.Variant == "Kiosk" then
		makePart({
			Name = "Counter",
			Size = Vector3.new(width - 6, 3.5, 3),
			Position = origin + Vector3.new(0, 1.75, -frontDirection * (depth / 2 - 3)),
			Color = Color3.fromRGB(103, 70, 47),
			Material = Enum.Material.Wood,
			Parent = location,
		})
	elseif definition.Variant == "Industrial" then
		for crateIndex, x in { -9, 9 } do
			makePart({
				Name = `CargoCrate{crateIndex}`,
				Size = Vector3.new(6, 5, 6),
				Position = origin + Vector3.new(x, 2.5, -frontDirection * (depth / 2 - 3)),
				Color = Color3.fromRGB(126, 88, 49),
				Material = Enum.Material.WoodPlanks,
				Parent = location,
			})
		end
	elseif definition.Variant == "Arcade" then
		for machineIndex, x in { -9, 9 } do
			makePart({
				Name = `ArcadeMachine{machineIndex}`,
				Size = Vector3.new(4, 6, 4),
				Position = origin + Vector3.new(x, 3, -frontDirection * (depth / 2 - 3)),
				Color = definition.AccentColor,
				Material = Enum.Material.Neon,
				Parent = location,
			})
		end
	else
		makePart({
			Name = "VaultBackplate",
			Size = Vector3.new(targetSize.X + 3, targetSize.Y + 2, 0.8),
			Position = targetPosition + Vector3.new(0, 0, -frontDirection * (targetSize.Z / 2 + 0.5)),
			Color = Color3.fromRGB(49, 56, 67),
			Material = Enum.Material.Metal,
			Parent = location,
		})
		for frameIndex, x in { -(targetSize.X / 2 + 0.8), targetSize.X / 2 + 0.8 } do
			makePart({
				Name = `VaultFrameSide{frameIndex}`,
				Size = Vector3.new(1.2, targetSize.Y + 2, targetSize.Z + 1),
				Position = targetPosition + Vector3.new(x, 0, 0),
				Color = Color3.fromRGB(49, 56, 67),
				Material = Enum.Material.Metal,
				Parent = location,
			})
		end
		makePart({
			Name = "VaultFrameTop",
			Size = Vector3.new(targetSize.X + 3, 1.2, targetSize.Z + 1),
			Position = targetPosition + Vector3.new(0, targetSize.Y / 2 + 0.7, 0),
			Color = Color3.fromRGB(49, 56, 67),
			Material = Enum.Material.Metal,
			Parent = location,
		})
	end

	local target = makePart({
		Name = "RobberyTarget",
		Size = targetSize,
		Position = targetPosition + Vector3.new(0, 0, -frontDirection * 0.6),
		Color = definition.AccentColor,
		Material = if definition.Variant == "Vault" then Enum.Material.DiamondPlate else Enum.Material.Metal,
		Parent = location,
	})
	target:SetAttribute("RobberyEnabled", true)
	target:SetAttribute("RobberyStoreId", definition.Id)
	addSurfaceLabel(target, definition.TargetName, frontFace)

	if definition.Variant == "Vault" then
		local vaultLight = makePart({
			Name = "VaultLight",
			Size = Vector3.new(2, 2, 0.4),
			Position = target.Position + Vector3.new(0, 0, frontDirection * (targetSize.Z / 2 + 0.3)),
			Color = Color3.fromRGB(255, 76, 76),
			Material = Enum.Material.Neon,
			CanCollide = false,
			CanQuery = false,
			Parent = location,
		})
		vaultLight.Shape = Enum.PartType.Ball
	end

	location.PrimaryPart = target
end

local function createRobberyLocations(parent: Instance)
	local robberyLocations = Instance.new("Model")
	robberyLocations.Name = "CityRobberyLocations"
	robberyLocations:SetAttribute("LocationCount", #RobberyLocationConfig.Locations)
	robberyLocations.Parent = parent

	local slots = {}
	local outerBlockOrdinal = 0
	for _, row in CityConfig.BlockCoordinates do
		for _, column in CityConfig.BlockCoordinates do
			if math.abs(row.Center) >= 500 or math.abs(column.Center) >= 500 then
				outerBlockOrdinal += 1
				-- Eight evenly spaced outer blocks remain as visual breathing room.
				if outerBlockOrdinal % 6 ~= 0 then
					table.insert(slots, { Row = row, Column = column })
				end
			end
		end
	end

	assert(#slots == #RobberyLocationConfig.Locations, "Mega City robbery slot count must match its location count")
	for locationIndex, definition in RobberyLocationConfig.Locations do
		local slot = slots[locationIndex]
		local row = slot.Row
		local column = slot.Column
		local frontDirection = if row.Center < 0 then 1 else -1
		local edgeClearance = if row.Size < 150 then 6 else 10
		local position = Vector3.new(
			column.Center,
			GameConfig.World.DrivingSurfaceY,
			row.Center + frontDirection * (row.Size / 2 - edgeClearance)
		)
		createRobberyLocation(robberyLocations, definition, position, frontDirection)
	end
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

local function createSatellitePoliceStations(parent: Instance)
	local precincts = Instance.new("Model")
	precincts.Name = "SatellitePolicePrecincts"
	precincts:SetAttribute("PrecinctCount", #satellitePrecincts)
	precincts.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY

	for _, definition in satellitePrecincts do
		local station = Instance.new("Model")
		station.Name = `{definition.Id}PolicePrecinct`
		station:SetAttribute("ResponseOrigin", true)
		station.Parent = precincts
		local center = Vector3.new(definition.Position.X, surfaceY, definition.Position.Z)
		local navy = Color3.fromRGB(31, 63, 112)

		local building = makePart({ Name = "PrecinctBuilding", Size = Vector3.new(70, 18, 48), Position = center + Vector3.new(0, 9, 0), Color = definition.Color, Material = Enum.Material.Concrete, Parent = station })
		makePart({ Name = "Roof", Size = Vector3.new(74, 1, 52), Position = center + Vector3.new(0, 18.5, 0), Color = navy, Material = Enum.Material.Metal, Parent = station })
		local sign = makePart({ Name = "PrecinctSign", Size = Vector3.new(34, 5, 0.7), Position = center + Vector3.new(0, 14, -24.5), Color = Color3.fromRGB(235, 240, 247), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = station })
		addSurfaceLabel(sign, definition.DisplayName, Enum.NormalId.Front)

		for windowIndex, x in { -25, -12, 12, 25 } do
			makePart({ Name = `FrontWindow{windowIndex}`, Size = Vector3.new(8, 6, 0.4), Position = center + Vector3.new(x, 7, -24.3), Color = Color3.fromRGB(118, 204, 232), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, CanQuery = false, Parent = station })
		end
		for bayIndex, x in { -13, 13 } do
			local bay = makePart({ Name = `GarageBay{bayIndex}`, Size = Vector3.new(20, 8, 0.5), Position = center + Vector3.new(x, 5, 24.3), Color = Color3.fromRGB(55, 62, 72), Material = Enum.Material.Metal, CanCollide = false, Parent = station })
			addSurfaceLabel(bay, `UNIT {bayIndex}`, Enum.NormalId.Back)
		end
		makePart({ Name = "RedBeacon", Size = Vector3.new(3, 0.7, 1), Position = center + Vector3.new(-3, 18.8, -24.5), Color = Color3.fromRGB(255, 66, 66), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = station })
		makePart({ Name = "BlueBeacon", Size = Vector3.new(3, 0.7, 1), Position = center + Vector3.new(3, 18.8, -24.5), Color = Color3.fromRGB(66, 136, 255), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = station })
		station.PrimaryPart = building
	end
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

local function createArrivalHub(parent: Instance, spawns: Instance)
	local hub = Instance.new("Model")
	hub.Name = "ArrivalHub"
	hub.Parent = parent
	local center = SpawnConfig.ArrivalPosition
	local platformY = center.Y - 4

	makePart({ Name = "HubPlatform", Size = Vector3.new(120, 2, 80), Position = Vector3.new(center.X, platformY, center.Z), Color = Color3.fromRGB(38, 48, 66), Material = Enum.Material.Slate, Parent = hub })
	makePart({ Name = "CenterGlow", Size = Vector3.new(42, 0.3, 24), Position = Vector3.new(center.X, platformY + 1.15, center.Z + 12), Color = Color3.fromRGB(79, 215, 255), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = hub })

	local wallColor = Color3.fromRGB(120, 205, 235)
	for wallIndex, wall in {
		{ Size = Vector3.new(120, 18, 1), Position = Vector3.new(center.X, platformY + 9, center.Z - 40) },
		{ Size = Vector3.new(120, 18, 1), Position = Vector3.new(center.X, platformY + 9, center.Z + 40) },
		{ Size = Vector3.new(1, 18, 80), Position = Vector3.new(center.X - 60, platformY + 9, center.Z) },
		{ Size = Vector3.new(1, 18, 80), Position = Vector3.new(center.X + 60, platformY + 9, center.Z) },
	} do
		makePart({ Name = `GlassBarrier{wallIndex}`, Size = wall.Size, Position = wall.Position, Color = wallColor, Material = Enum.Material.Glass, Transparency = 0.55, Parent = hub })
	end

	local title = makePart({ Name = "ArrivalTitle", Size = Vector3.new(54, 7, 1), Position = Vector3.new(center.X, platformY + 12, center.Z + 31), Color = Color3.fromRGB(22, 30, 43), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = hub })
	addSurfaceLabel(title, "CHOOSE YOUR DISTRICT", Enum.NormalId.Front)
	local subtitle = makePart({ Name = "ArrivalSubtitle", Size = Vector3.new(42, 3, 0.7), Position = Vector3.new(center.X, platformY + 7, center.Z + 30.8), Color = Color3.fromRGB(68, 82, 105), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = hub })
	addSurfaceLabel(subtitle, "YOUR CHOICE BECOMES YOUR RESPAWN", Enum.NormalId.Front)

	local arrivalSpawn = Instance.new("SpawnLocation")
	arrivalSpawn.Name = "ArrivalSpawn"
	arrivalSpawn.Anchored = true
	arrivalSpawn.Size = Vector3.new(14, 1, 14)
	arrivalSpawn.Position = center
	arrivalSpawn.Color = Color3.fromRGB(79, 215, 255)
	arrivalSpawn.Material = Enum.Material.Neon
	arrivalSpawn.Transparency = 0.25
	arrivalSpawn.Neutral = true
	arrivalSpawn.Parent = spawns

	local gateSpacing = 21
	for choiceIndex, choice in SpawnConfig.Choices do
		local gatePosition = Vector3.new(
			center.X + (choiceIndex - 3) * gateSpacing,
			platformY + 3.5,
			center.Z - 22
		)
		local gate = makePart({ Name = `SpawnGate_{choice.Id}`, Size = Vector3.new(17, 7, 3), Position = gatePosition, Color = choice.Color, Material = Enum.Material.Neon, Parent = hub })
		gate:SetAttribute("SpawnChoiceId", choice.Id)
		addSurfaceLabel(gate, choice.DisplayName, Enum.NormalId.Back)
		local gateBase = makePart({ Name = `GateBase_{choice.Id}`, Size = Vector3.new(18, 0.5, 10), Position = gatePosition + Vector3.new(0, -3.25, 4), Color = choice.Color, Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = hub })
		gateBase:SetAttribute("SpawnChoiceId", choice.Id)
	end
end

local function createDistrictSpawnsAndRentals(parent: Instance, spawns: Instance)
	local districtSpawns = Instance.new("Folder")
	districtSpawns.Name = "DistrictSpawns"
	districtSpawns.Parent = spawns
	local rentals = Instance.new("Model")
	rentals.Name = "RentalDepots"
	rentals.Parent = parent
	local surfaceY = GameConfig.World.DrivingSurfaceY

	for _, choice in SpawnConfig.Choices do
		local pad = makePart({ Name = `ArrivalPad_{choice.Id}`, Size = Vector3.new(12, 0.2, 12), Position = Vector3.new(choice.Position.X, surfaceY + 0.12, choice.Position.Z), Color = choice.Color, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = rentals })
		addSurfaceLabel(pad, choice.DisplayName, Enum.NormalId.Top)

		local destination = Instance.new("SpawnLocation")
		destination.Name = `DistrictSpawn_{choice.Id}`
		destination.Anchored = true
		destination.Size = Vector3.new(8, 1, 8)
		destination.Position = Vector3.new(choice.Position.X, surfaceY + 0.6, choice.Position.Z)
		destination.Transparency = 1
		destination.CanCollide = false
		destination.CanQuery = false
		destination.Neutral = true
		destination:SetAttribute("SpawnChoiceId", choice.Id)
		destination.Parent = districtSpawns

		local kioskPosition = Vector3.new(choice.RentalKioskPosition.X, surfaceY, choice.RentalKioskPosition.Z)
		makePart({ Name = `RentalStand_{choice.Id}`, Size = Vector3.new(14, 0.4, 10), Position = kioskPosition + Vector3.new(0, 0.22, 0), Color = Color3.fromRGB(55, 62, 75), Material = Enum.Material.Metal, Parent = rentals })
		local kiosk = makePart({ Name = `RentalKiosk_{choice.Id}`, Size = Vector3.new(8, 7, 4), Position = kioskPosition + Vector3.new(0, 3.7, 0), Color = choice.Color, Material = Enum.Material.SmoothPlastic, Parent = rentals })
		kiosk:SetAttribute("RentalKioskId", choice.Id)
		addSurfaceLabel(kiosk, "RENT GLEEP GLORP\n$100", Enum.NormalId.Front)
		local roof = makePart({ Name = `RentalRoof_{choice.Id}`, Size = Vector3.new(13, 0.7, 9), Position = kioskPosition + Vector3.new(0, 8, 0), Color = Color3.fromRGB(35, 41, 54), Material = Enum.Material.Metal, Parent = rentals })
		roof:SetAttribute("RentalKioskId", choice.Id)

		local rentalMarker = makePart({ Name = `RentalSpawn_{choice.Id}`, Size = Vector3.new(9, 0.2, 16), Position = Vector3.new(choice.RentalSpawnPosition.X, surfaceY + 0.12, choice.RentalSpawnPosition.Z), Color = choice.Color, Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, CanQuery = false, Parent = spawns })
		rentalMarker.CFrame = CFrame.new(rentalMarker.Position) * CFrame.Angles(0, math.rad(choice.RentalSpawnYaw), 0)
		rentalMarker:SetAttribute("RentalSpawnId", choice.Id)
		addSurfaceLabel(rentalMarker, "RENTAL CAR", Enum.NormalId.Top)
	end
end

local function createSpawns(parent: Instance)
	local spawns = Instance.new("Folder")
	spawns.Name = "Spawns"
	spawns.Parent = parent
	createArrivalHub(parent, spawns)
	createDistrictSpawnsAndRentals(parent, spawns)

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

	for _, precinct in satellitePrecincts do
		for laneIndex, laneOffset in { -8, 8 } do
			local offset = if precinct.MarkerAxis == "X"
				then Vector3.new(laneOffset, 0, 0)
				else Vector3.new(0, 0, laneOffset)
			local marker = makePart({
				Name = `{precinct.Id}Response{laneIndex}`,
				Size = Vector3.new(4, 1, 4),
				Position = Vector3.new(precinct.ResponsePosition.X, GameConfig.World.DrivingSurfaceY, precinct.ResponsePosition.Z) + offset,
				Color = Color3.fromRGB(30, 100, 230),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				Parent = policeSpawns,
			})
			marker:SetAttribute("SpawnType", "PoliceResponse")
			marker:SetAttribute("PrecinctId", precinct.Id)
		end
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
	createCityDetails(world)
	createRoadNetwork(world)
	createBoundary(world)

	local landmarks = Instance.new("Model")
	landmarks.Name = "Landmarks"
	landmarks.Parent = world
	createConvenienceStore(landmarks)
	createRobberyLocations(landmarks)
	createPoliceStation(landmarks)
	createSatellitePoliceStations(landmarks)
	createJail(landmarks)
	createSpawns(world)

	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.35
end

return table.freeze(WorldService)
