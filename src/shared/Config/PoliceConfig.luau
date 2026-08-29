--!strict

local responseSpeeds: { [number]: number } = {
	[1] = 48,
	[2] = 56,
	[3] = 64,
	[4] = 72,
	[5] = 80,
}

local escapeSecondsPerLevel: { [number]: number } = {
	[1] = 8,
	[2] = 10,
	[3] = 12,
	[4] = 14,
	[5] = 16,
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
		MaximumTrackingTime = 18,
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

	Search = {
		SightCheckInterval = 0.2,
		MaximumSightDistance = 130,
		LostSightGrace = 2.5,
		EscapeSecondsPerLevel = escapeSecondsPerLevel,
		SweepRadius = 18,
		SweepInterval = 3,
		VehicleSpeed = 38,
		ArrivalDistance = 16,
	},

	Return = {
		ArrivalDistance = 12,
		Timeout = 20,
		VehicleSpeed = 34,
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
