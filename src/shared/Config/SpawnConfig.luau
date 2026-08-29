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
		Color = Color3.fromRGB(94, 224, 255),
	},
	{
		Id = "Northside",
		DisplayName = "NORTHSIDE",
		Position = Vector3.new(-703, 0, -703),
		RentalKioskPosition = Vector3.new(-693, 0, -703),
		RentalSpawnPosition = Vector3.new(-670, 0, -734),
		RentalSpawnYaw = 90,
		Color = Color3.fromRGB(126, 232, 127),
	},
	{
		Id = "Eastside",
		DisplayName = "EASTSIDE",
		Position = Vector3.new(703, 0, -503),
		RentalKioskPosition = Vector3.new(703, 0, -493),
		RentalSpawnPosition = Vector3.new(734, 0, -470),
		RentalSpawnYaw = 0,
		Color = Color3.fromRGB(255, 197, 91),
	},
	{
		Id = "Southside",
		DisplayName = "SOUTHSIDE",
		Position = Vector3.new(503, 0, 703),
		RentalKioskPosition = Vector3.new(493, 0, 703),
		RentalSpawnPosition = Vector3.new(470, 0, 734),
		RentalSpawnYaw = 90,
		Color = Color3.fromRGB(255, 125, 175),
	},
	{
		Id = "Westside",
		DisplayName = "WESTSIDE",
		Position = Vector3.new(-703, 0, 503),
		RentalKioskPosition = Vector3.new(-703, 0, 493),
		RentalSpawnPosition = Vector3.new(-734, 0, 470),
		RentalSpawnYaw = 0,
		Color = Color3.fromRGB(180, 134, 255),
	},
}

local SpawnConfig = {
	ArrivalPosition = Vector3.new(0, 132, 0),
	InteractionDistance = 12,
	RentalCost = 100,
	Choices = choices,
}

return table.freeze(SpawnConfig)
