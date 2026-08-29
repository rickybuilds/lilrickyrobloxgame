--!strict

export type BuildingStyle = "Storefront" | "Civic" | "Warehouse" | "Tower" | "Residential"

export type BuildingDefinition = {
	Name: string,
	DisplayName: string,
	Position: Vector3,
	Size: Vector3,
	Color: Color3,
	AccentColor: Color3,
	Style: BuildingStyle,
}

export type BlockCoordinate = {
	Center: number,
	Size: number,
}

local roadCenters = { -734, -580, -426, -272, 0, 272, 426, 580, 734 }

-- Road edges and a small visual gutter determine these block dimensions. The
-- two central rows/columns preserve the original Milestone 1-5 landmark area.
local blockCoordinates: { BlockCoordinate } = {
	{ Center = -657, Size = 102 },
	{ Center = -503, Size = 102 },
	{ Center = -349, Size = 102 },
	{ Center = -136, Size = 220 },
	{ Center = 136, Size = 220 },
	{ Center = 349, Size = 102 },
	{ Center = 503, Size = 102 },
	{ Center = 657, Size = 102 },
}

local buildings: { BuildingDefinition } = {
	{
		Name = "NorthsideHomes",
		DisplayName = "NORTHSIDE HOMES",
		Position = Vector3.new(-349, 0, -349),
		Size = Vector3.new(78, 30, 64),
		Color = Color3.fromRGB(185, 125, 103),
		AccentColor = Color3.fromRGB(245, 210, 151),
		Style = "Residential",
	},
	{
		Name = "PixelPalaceArcade",
		DisplayName = "PIXEL PALACE",
		Position = Vector3.new(-136, 0, -349),
		Size = Vector3.new(92, 26, 68),
		Color = Color3.fromRGB(89, 65, 150),
		AccentColor = Color3.fromRGB(83, 239, 235),
		Style = "Storefront",
	},
	{
		Name = "FireStation",
		DisplayName = "FIRE STATION",
		Position = Vector3.new(136, 0, -349),
		Size = Vector3.new(94, 28, 68),
		Color = Color3.fromRGB(178, 67, 57),
		AccentColor = Color3.fromRGB(245, 215, 120),
		Style = "Civic",
	},
	{
		Name = "GlorpTower",
		DisplayName = "GLORP TOWER",
		Position = Vector3.new(349, 0, -349),
		Size = Vector3.new(76, 58, 66),
		Color = Color3.fromRGB(71, 107, 142),
		AccentColor = Color3.fromRGB(121, 214, 231),
		Style = "Tower",
	},
	{
		Name = "WestsideWarehouse",
		DisplayName = "WESTSIDE WAREHOUSE",
		Position = Vector3.new(-349, 0, -136),
		Size = Vector3.new(80, 27, 82),
		Color = Color3.fromRGB(119, 126, 132),
		AccentColor = Color3.fromRGB(236, 166, 69),
		Style = "Warehouse",
	},
	{
		Name = "CornerCafe",
		DisplayName = "CORNER CAFE",
		Position = Vector3.new(-218, 0, -218),
		Size = Vector3.new(48, 20, 42),
		Color = Color3.fromRGB(171, 102, 72),
		AccentColor = Color3.fromRGB(255, 206, 108),
		Style = "Storefront",
	},
	{
		Name = "MoonlightDiner",
		DisplayName = "MOONLIGHT DINER",
		Position = Vector3.new(215, 0, -211),
		Size = Vector3.new(58, 18, 38),
		Color = Color3.fromRGB(68, 146, 151),
		AccentColor = Color3.fromRGB(247, 104, 143),
		Style = "Storefront",
	},
	{
		Name = "GlorpAutoWorks",
		DisplayName = "GLORP AUTO WORKS",
		Position = Vector3.new(349, 0, -136),
		Size = Vector3.new(82, 24, 80),
		Color = Color3.fromRGB(75, 82, 92),
		AccentColor = Color3.fromRGB(74, 176, 242),
		Style = "Warehouse",
	},
	{
		Name = "WestParkingGarage",
		DisplayName = "WEST PARKING",
		Position = Vector3.new(-349, 0, 136),
		Size = Vector3.new(80, 24, 80),
		Color = Color3.fromRGB(93, 105, 120),
		AccentColor = Color3.fromRGB(244, 201, 86),
		Style = "Civic",
	},
	{
		Name = "CityTech",
		DisplayName = "CITY TECH",
		Position = Vector3.new(-216, 0, 215),
		Size = Vector3.new(52, 30, 46),
		Color = Color3.fromRGB(72, 105, 124),
		AccentColor = Color3.fromRGB(97, 222, 197),
		Style = "Tower",
	},
	{
		Name = "FamilyFunCenter",
		DisplayName = "FAMILY FUN CENTER",
		Position = Vector3.new(211, 0, 218),
		Size = Vector3.new(56, 22, 44),
		Color = Color3.fromRGB(209, 112, 75),
		AccentColor = Color3.fromRGB(247, 217, 76),
		Style = "Storefront",
	},
	{
		Name = "MegaMart",
		DisplayName = "MEGA MART",
		Position = Vector3.new(349, 0, 136),
		Size = Vector3.new(84, 25, 82),
		Color = Color3.fromRGB(77, 139, 91),
		AccentColor = Color3.fromRGB(248, 224, 94),
		Style = "Storefront",
	},
	{
		Name = "RiversideApartments",
		DisplayName = "RIVERSIDE",
		Position = Vector3.new(-349, 0, 349),
		Size = Vector3.new(78, 42, 66),
		Color = Color3.fromRGB(100, 132, 165),
		AccentColor = Color3.fromRGB(215, 229, 240),
		Style = "Residential",
	},
	{
		Name = "CityLibrary",
		DisplayName = "CITY LIBRARY",
		Position = Vector3.new(-136, 0, 349),
		Size = Vector3.new(90, 31, 66),
		Color = Color3.fromRGB(151, 119, 91),
		AccentColor = Color3.fromRGB(224, 202, 151),
		Style = "Civic",
	},
	{
		Name = "SunnySchool",
		DisplayName = "SUNNY SCHOOL",
		Position = Vector3.new(136, 0, 349),
		Size = Vector3.new(94, 30, 68),
		Color = Color3.fromRGB(194, 154, 73),
		AccentColor = Color3.fromRGB(69, 119, 173),
		Style = "Civic",
	},
	{
		Name = "DistributionCenter",
		DisplayName = "DISTRIBUTION",
		Position = Vector3.new(349, 0, 349),
		Size = Vector3.new(82, 27, 70),
		Color = Color3.fromRGB(117, 121, 126),
		AccentColor = Color3.fromRGB(229, 140, 65),
		Style = "Warehouse",
	},
}

local CityConfig = {
	RoadCenters = roadCenters,
	BlockCoordinates = blockCoordinates,
	Buildings = buildings,
	AlleyWidth = 14,
	BoundaryInset = 7,
}

return table.freeze(CityConfig)
