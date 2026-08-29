--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VehicleConfig = require(ReplicatedStorage.Shared.Config.VehicleConfig)

export type ControlState = {
	Throttle: number,
	Steering: number,
	Brake: number,
	Handbrake: boolean,
	Parked: boolean,
}

type Runtime = {
	Root: BasePart,
	DriveForce: VectorForce,
	GripForce: VectorForce,
	SteeringVelocity: AngularVelocity,
	StabilityTorque: Torque,
	SuspensionForces: { [string]: VectorForce },
	SuspensionAttachments: { [string]: Attachment },
	WheelMotors: { [string]: Motor6D },
	RaycastParams: RaycastParams,
	WheelSpin: number,
}

local VehicleDynamics = {}
local wheelNames = { "FL", "FR", "RL", "RR" }
local runtimeCache: { [Model]: Runtime } = setmetatable({}, { __mode = "k" }) :: any

local function expectChild(parent: Instance, name: string, className: string): Instance
	local child = parent:FindFirstChild(name)
	assert(child, `{parent:GetFullName()} is missing {name}`)
	assert(child:IsA(className), `{child:GetFullName()} must be a {className}`)
	return child
end

local function getRuntime(vehicle: Model): Runtime
	local cached = runtimeCache[vehicle]
	if cached then
		return cached
	end

	local root = expectChild(vehicle, "ChassisRoot", "BasePart") :: BasePart
	local suspensionForces: { [string]: VectorForce } = {}
	local suspensionAttachments: { [string]: Attachment } = {}
	local wheelMotors: { [string]: Motor6D } = {}

	for _, wheelName in wheelNames do
		suspensionForces[wheelName] = expectChild(root, `SuspensionForce{wheelName}`, "VectorForce") :: VectorForce
		suspensionAttachments[wheelName] = expectChild(root, `Suspension{wheelName}`, "Attachment") :: Attachment
		wheelMotors[wheelName] = expectChild(root, `WheelMotor{wheelName}`, "Motor6D") :: Motor6D
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { vehicle }
	raycastParams.IgnoreWater = true
	raycastParams.RespectCanCollide = true

	local runtime: Runtime = {
		Root = root,
		DriveForce = expectChild(root, "DriveForce", "VectorForce") :: VectorForce,
		GripForce = expectChild(root, "GripForce", "VectorForce") :: VectorForce,
		SteeringVelocity = expectChild(root, "SteeringVelocity", "AngularVelocity") :: AngularVelocity,
		StabilityTorque = expectChild(root, "StabilityTorque", "Torque") :: Torque,
		SuspensionForces = suspensionForces,
		SuspensionAttachments = suspensionAttachments,
		WheelMotors = wheelMotors,
		RaycastParams = raycastParams,
		WheelSpin = 0,
	}

	runtimeCache[vehicle] = runtime
	return runtime
end

local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function unitOrFallback(vector: Vector3, fallback: Vector3): Vector3
	return if vector.Magnitude > 0.001 then vector.Unit else fallback
end

local function clampVector(vector: Vector3, maximumMagnitude: number): Vector3
	if vector.Magnitude <= maximumMagnitude then
		return vector
	end
	return vector.Unit * maximumMagnitude
end

local function zeroDrivingForces(runtime: Runtime)
	runtime.DriveForce.Force = Vector3.zero
	runtime.GripForce.Force = Vector3.zero
	runtime.SteeringVelocity.AngularVelocity = Vector3.zero
	runtime.SteeringVelocity.Enabled = false
end

local function animateWheels(runtime: Runtime, steering: number, forwardSpeed: number, deltaTime: number)
	runtime.WheelSpin += (forwardSpeed / VehicleConfig.Chassis.WheelRadius) * deltaTime
	local steeringAngle = steering * math.rad(28)

	for wheelName, motor in runtime.WheelMotors do
		local yaw = if wheelName == "FL" or wheelName == "FR" then steeringAngle else 0
		motor.Transform = CFrame.Angles(0, yaw, 0) * CFrame.Angles(runtime.WheelSpin, 0, 0)
	end
end

function VehicleDynamics.Step(vehicle: Model, controls: ControlState, deltaTime: number): number
	local runtime = getRuntime(vehicle)
	local root = runtime.Root
	local mass = math.max(root.AssemblyMass, 1)
	local up = root.CFrame.UpVector
	local forward = unitOrFallback(horizontal(root.CFrame.LookVector), Vector3.new(0, 0, -1))
	local right = unitOrFallback(horizontal(root.CFrame.RightVector), Vector3.new(1, 0, 0))
	local velocity = root.AssemblyLinearVelocity
	local horizontalVelocity = horizontal(velocity)
	local forwardSpeed = horizontalVelocity:Dot(forward)
	local lateralSpeed = horizontalVelocity:Dot(right)
	local groundedWheels = 0

	for _, wheelName in wheelNames do
		local attachment = runtime.SuspensionAttachments[wheelName]
		local suspensionForce = runtime.SuspensionForces[wheelName]
		local result = Workspace:Raycast(
			attachment.WorldPosition,
			-up * VehicleConfig.Suspension.RayLength,
			runtime.RaycastParams
		)

		if result then
			groundedWheels += 1
			local compression = VehicleConfig.Suspension.RestLength - result.Distance
			local pointVelocity = root:GetVelocityAtPosition(attachment.WorldPosition):Dot(up)
			local supportForce = (mass * Workspace.Gravity) / 4
			local springForce = compression * VehicleConfig.Suspension.SpringStiffness
			local dampingForce = -pointVelocity * VehicleConfig.Suspension.Damping
			local forceMagnitude = math.clamp(
				supportForce + springForce + dampingForce,
				0,
				VehicleConfig.Suspension.MaximumForcePerWheel
			)
			suspensionForce.Force = up * forceMagnitude
		else
			suspensionForce.Force = Vector3.zero
		end
	end

	local disabled = vehicle:GetAttribute(VehicleConfig.Attributes.Disabled) == true
	local parked = disabled or controls.Parked
	local throttle = if parked then 0 else math.clamp(controls.Throttle, -1, 1)
	local steering = if parked then 0 else math.clamp(controls.Steering, -1, 1)
	local brake = if parked then 1 else math.clamp(controls.Brake, 0, 1)
	local handbrake = if parked then true else controls.Handbrake

	if groundedWheels > 0 then
		local driveForce = Vector3.zero
		if throttle > 0 then
			if forwardSpeed < -1 then
				driveForce = forward * mass * VehicleConfig.Handling.BrakeAcceleration * throttle
			else
				local speedScale = math.clamp(1 - math.max(forwardSpeed, 0) / VehicleConfig.Handling.MaximumForwardSpeed, 0, 1)
				driveForce = forward * mass * VehicleConfig.Handling.ForwardAcceleration * throttle * speedScale
			end
		elseif throttle < 0 then
			if forwardSpeed > 1 then
				driveForce = forward * mass * VehicleConfig.Handling.BrakeAcceleration * throttle
			else
				local speedScale = math.clamp(1 - math.abs(math.min(forwardSpeed, 0)) / VehicleConfig.Handling.MaximumReverseSpeed, 0, 1)
				driveForce = forward * mass * VehicleConfig.Handling.ReverseAcceleration * throttle * speedScale
			end
		end

		if math.abs(forwardSpeed) > 0.2 then
			local brakingAcceleration = brake * VehicleConfig.Handling.BrakeAcceleration
					+ (if handbrake then VehicleConfig.Handling.HandbrakeDrag else 0)
			driveForce += -forward * math.sign(forwardSpeed) * mass * brakingAcceleration
		end

		driveForce += -forward * forwardSpeed * mass * VehicleConfig.Handling.RollingResistance
		driveForce += -horizontalVelocity * mass * VehicleConfig.Handling.AerodynamicDrag
		if parked then
			driveForce += -horizontalVelocity * mass * VehicleConfig.Handling.ParkDrag
		end
		runtime.DriveForce.Force = driveForce

		local grip = if parked
			then VehicleConfig.Handling.ParkGrip
			elseif handbrake then VehicleConfig.Handling.HandbrakeGrip
			else VehicleConfig.Handling.LateralGrip
		local lateralForce = -right * lateralSpeed * mass * grip
		runtime.GripForce.Force = clampVector(
			lateralForce,
			mass * VehicleConfig.Handling.MaximumLateralAcceleration
		)

		local speedFraction = math.clamp(math.abs(forwardSpeed) / VehicleConfig.Handling.MaximumForwardSpeed, 0, 1)
		local highSpeedScale = 1 - (1 - VehicleConfig.Handling.HighSpeedSteeringScale) * speedFraction
		local lowSpeedScale = math.clamp(
			math.abs(forwardSpeed) / VehicleConfig.Handling.MinimumSteeringSpeed,
			0,
			1
		)
		local direction = if math.abs(forwardSpeed) > 1 then math.sign(forwardSpeed) else math.sign(throttle)
		local yawRate = -steering
			* VehicleConfig.Handling.MaximumYawRate
			* highSpeedScale
			* lowSpeedScale
			* direction
		runtime.SteeringVelocity.MaxTorque = mass * VehicleConfig.Handling.SteeringTorquePerMass
		runtime.SteeringVelocity.AngularVelocity = Vector3.new(0, yawRate, 0)
		runtime.SteeringVelocity.Enabled = math.abs(yawRate) > 0.001

		local angularVelocity = root.AssemblyAngularVelocity
		local uprightAxis = up:Cross(Vector3.yAxis)
		local uprightTorque = uprightAxis * VehicleConfig.Handling.UprightStrength * mass
			- Vector3.new(angularVelocity.X, 0, angularVelocity.Z)
				* VehicleConfig.Handling.UprightDamping
				* mass
		runtime.StabilityTorque.Torque = clampVector(
			uprightTorque,
			mass * VehicleConfig.Handling.MaximumUprightTorquePerMass
		)
	else
		zeroDrivingForces(runtime)
		runtime.StabilityTorque.Torque = Vector3.zero
	end

	animateWheels(runtime, steering, forwardSpeed, deltaTime)
	return horizontalVelocity.Magnitude
end

function VehicleDynamics.ResetForces(vehicle: Model)
	local runtime = getRuntime(vehicle)
	zeroDrivingForces(runtime)
	runtime.StabilityTorque.Torque = Vector3.zero
	for _, suspensionForce in runtime.SuspensionForces do
		suspensionForce.Force = Vector3.zero
	end
end

return table.freeze(VehicleDynamics)
