--!strict

-- All handling values for the first arcade car live here. Future cars can copy
-- this shape and change tuning without changing VehicleDynamics.
local VehicleConfig = {
	ModelName = "StarterCar",
	DisplayName = "Ricky Roadster",

	Attributes = {
		IsVehicle = "IsVehicle",
		DriverUserId = "DriverUserId",
		Health = "VehicleHealth",
		MaxHealth = "VehicleMaxHealth",
		Disabled = "VehicleDisabled",
		Parked = "VehicleParked",
	},

	Health = {
		Maximum = 100,
	},

	Chassis = {
		RootSize = Vector3.new(7.6, 1.2, 12.8),
		WheelRadius = 1.5,
		WheelWidth = 1.2,
		WheelOffsets = {
			FL = Vector3.new(-4.05, -0.45, -4.25),
			FR = Vector3.new(4.05, -0.45, -4.25),
			RL = Vector3.new(-4.05, -0.45, 4.25),
			RR = Vector3.new(4.05, -0.45, 4.25),
		},
		SuspensionOffsets = {
			FL = Vector3.new(-3.25, -0.1, -4.25),
			FR = Vector3.new(3.25, -0.1, -4.25),
			RL = Vector3.new(-3.25, -0.1, 4.25),
			RR = Vector3.new(3.25, -0.1, 4.25),
		},
	},

	Suspension = {
		RestLength = 2.2,
		RayLength = 3.2,
		SpringStiffness = 6_500,
		Damping = 800,
		MaximumForcePerWheel = 65_000,
	},

	Handling = {
		MaximumForwardSpeed = 85, -- studs per second
		MaximumReverseSpeed = 30,
		ForwardAcceleration = 44, -- studs per second squared
		ReverseAcceleration = 30,
		BrakeAcceleration = 65,
		RollingResistance = 0.75,
		AerodynamicDrag = 0.18,
		LateralGrip = 5.2,
		HandbrakeGrip = 1.4,
		HandbrakeDrag = 7,
		ParkGrip = 14,
		ParkDrag = 12,
		ParkAngularDamping = 40,
		MaximumLateralAcceleration = 65,
		MaximumYawRate = math.rad(70),
		MinimumSteeringSpeed = 3,
		HighSpeedSteeringScale = 0.28,
		SteeringTorquePerMass = 260,
		UprightStrength = 280,
		UprightDamping = 48,
		MaximumUprightTorquePerMass = 550,
	},

	Input = {
		ThrottleResponse = 4.5,
		SteeringResponse = 5.5,
	},

	Security = {
		MaximumPlausibleSpeedMultiplier = 3,
		MaximumWorldCoordinate = 2_000,
	},

	Interaction = {
		PromptDistance = 10,
		ExitCooldown = 0.75,
	},

	Display = {
		StudsPerSecondToMPH = 0.626,
	},
}

return table.freeze(VehicleConfig)
