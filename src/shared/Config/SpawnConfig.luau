--!strict

export type SpawnChoice = {
	Id: string,
	DisplayName: string,
	Position: Vector3,
	RentalKioskPosition: Vector3,
	RentalSpawnPosition: Vector3,
	RentalSpawnYaw: number,
	Color: Color3,
}

local choices: { SpawnChoice } = {
	{
		Id = "Downtown",
		DisplayName = "DOWNTOWN",
		Position = Vector3.new(32, 0, 32),
		RentalKioskPosition = Vector3.new(42, 0, 32),
		RentalSpawnPosition = Vector3.new(58, 0, 0),
		RentalSpawnYaw = 90,
		Color = Color3.fromRGB(65, 105, 132),
	},
	{
		Id = "Northside",
		DisplayName = "NORTHSIDE",
		Position = Vector3.new(-703, 0, -703),
		RentalKioskPosition = Vector3.new(-693, 0, -703),
		RentalSpawnPosition = Vector3.new(-670, 0, -734),
		RentalSpawnYaw = 90,
		Color = Color3.fromRGB(75, 120, 82),
	},
	{
		Id = "Eastside",
		DisplayName = "EASTSIDE",
		Position = Vector3.new(703, 0, -503),
		RentalKioskPosition = Vector3.new(703, 0, -493),
		RentalSpawnPosition = Vector3.new(734, 0, -470),
		RentalSpawnYaw = 0,
		Color = Color3.fromRGB(153, 117, 55),
	},
	{
		Id = "Southside",
		DisplayName = "SOUTHSIDE",
		Position = Vector3.new(503, 0, 703),
		RentalKioskPosition = Vector3.new(493, 0, 703),
		RentalSpawnPosition = Vector3.new(470, 0, 734),
		RentalSpawnYaw = 90,
		Color = Color3.fromRGB(142, 73, 98),
	},
	{
		Id = "Westside",
		DisplayName = "WESTSIDE",
		Position = Vector3.new(-703, 0, 503),
		RentalKioskPosition = Vector3.new(-703, 0, 493),
		RentalSpawnPosition = Vector3.new(-734, 0, 470),
		RentalSpawnYaw = 0,
		Color = Color3.fromRGB(101, 78, 136),
	},
}

local SpawnConfig = {
	-- The enclosed terminal lives below the map so its exterior never appears in
	-- the city skyline. District gates teleport players back to street level.
	ArrivalPosition = Vector3.new(0, -60, 0),
	InteractionDistance = 12,
	RentalCost = 100,
	Choices = choices,
	ReleaseRental = {
		Id = "JailRelease",
		KioskPosition = Vector3.new(-173, 0, 99),
		SpawnPosition = Vector3.new(-205, 0, 75),
		SpawnYaw = 90,
		Color = Color3.fromRGB(66, 91, 126),
	},
}

return table.freeze(SpawnConfig)
