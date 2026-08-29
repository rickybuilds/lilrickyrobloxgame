--!strict

local responseSpeeds: { [number]: number } = {
	[1] = 48,
	[2] = 56,
	[3] = 64,
	[4] = 72,
	[5] = 80,
}

local PoliceConfig = {
	Attributes = {
		Arrested = "Arrested",
		IsPoliceVehicle = "IsPoliceVehicle",
		TargetUserId = "PoliceTargetUserId",
	},

	Dispatch = {
		MinimumSpawnDistance = 70,
		RetryInterval = 1,
	},

	Vehicle = {
		DismountDistance = 38,
		ApproachSlowDistance = 55,
		ObstacleCheckDistance = 20,
		StuckTime = 2.5,
		ReverseTime = 1.2,
		ResponseSpeeds = responseSpeeds,
	},

	Officer = {
		WalkSpeed = 19,
		PathRefreshInterval = 0.8,
		WaypointReachedDistance = 3.5,
		ReboardDistance = 8,
	},

	Arrest = {
		Distance = 7,
		HoldDuration = 1.5,
		MaximumSuspectSpeed = 14,
		ConfiscationFraction = 0.2,
		JailDuration = 5,
	},
}

return table.freeze(PoliceConfig)
