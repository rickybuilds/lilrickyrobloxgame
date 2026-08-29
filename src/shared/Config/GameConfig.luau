--!strict

-- Central tuning values shared by the server and client.
-- Gameplay code should read this table instead of scattering magic numbers.
local GameConfig = {
	GameName = "Ricky's City",
	WorldVersion = 3,

	PlayerDefaults = {
		Money = 0,
		WantedLevel = 0,
		RobberyStatus = "Explore the city",
		Arrested = false,
	},

	Wanted = {
		MinimumLevel = 0,
		MaximumLevel = 5,
	},

	Attributes = {
		Money = "Money",
		WantedLevel = "WantedLevel",
		RobberyStatus = "RobberyStatus",
		Arrested = "Arrested",
	},

	World = {
		ContainerName = "GameWorld",
		MapSize = 512,
		RoadWidth = 44,
		DrivingSurfaceY = 1,
	},
}

return table.freeze(GameConfig)
