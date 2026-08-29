--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VehicleConfig = require(ReplicatedStorage.Shared.Config.VehicleConfig)
local VehicleDynamics = require(ReplicatedStorage.Shared.Vehicle.VehicleDynamics)

type VehicleSeatType = Seat | VehicleSeat

type VehicleRecord = {
	Model: Model,
	Root: BasePart,
	DriverSeat: VehicleSeat,
	PassengerSeat: Seat,
	DriverPrompt: ProximityPrompt,
	PassengerPrompt: ProximityPrompt,
	LastSafeCFrame: CFrame,
}

type SeatAssignment = {
	Record: VehicleRecord,
	Seat: VehicleSeatType,
}

local VehicleService = {}
local records: { [Model]: VehicleRecord } = {}
local npcVehicles: { [Model]: boolean } = {}
local seatAssignments: { [Player]: SeatAssignment } = {}
local lastExitTimes: { [Player]: number } = {}
local lastParkRequestTimes: { [Player]: number } = {}
local started = false
local exitVehicleRemote: RemoteEvent
local setVehicleParkedRemote: RemoteEvent

local IDLE_CONTROLS: VehicleDynamics.ControlState = {
	Throttle = 0,
	Steering = 0,
	Brake = 0,
	Handbrake = false,
	Parked = true,
}

local function makePart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function weldToRoot(root: BasePart, part: BasePart)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false

	local weld = Instance.new("WeldConstraint")
	weld.Name = `Weld{part.Name}`
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function makeVisualPart(
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = makePart(name, size, root.CFrame * localCFrame, color, material, parent)
	weldToRoot(root, part)
	return part
end

local function makePromptAnchor(
	root: BasePart,
	name: string,
	localPosition: Vector3,
	actionText: string,
	parent: Instance
): (Part, ProximityPrompt)
	local anchor = makeVisualPart(
		root,
		name,
		Vector3.new(1, 3, 4),
		CFrame.new(localPosition),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		parent
	)
	anchor.Transparency = 1

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SeatPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = VehicleConfig.DisplayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = VehicleConfig.Interaction.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	return anchor, prompt
end

local function makeCenterActuators(root: BasePart)
	local center = Instance.new("Attachment")
	center.Name = "CenterAttachment"
	center.Parent = root

	local driveForce = Instance.new("VectorForce")
	driveForce.Name = "DriveForce"
	driveForce.Attachment0 = center
	driveForce.RelativeTo = Enum.ActuatorRelativeTo.World
	driveForce.ApplyAtCenterOfMass = true
	driveForce.Force = Vector3.zero
	driveForce.Parent = root

	local gripForce = Instance.new("VectorForce")
	gripForce.Name = "GripForce"
	gripForce.Attachment0 = center
	gripForce.RelativeTo = Enum.ActuatorRelativeTo.World
	gripForce.ApplyAtCenterOfMass = true
	gripForce.Force = Vector3.zero
	gripForce.Parent = root

	local steeringVelocity = Instance.new("AngularVelocity")
	steeringVelocity.Name = "SteeringVelocity"
	steeringVelocity.Attachment0 = center
	steeringVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	steeringVelocity.AngularVelocity = Vector3.zero
	steeringVelocity.MaxTorque = 0
	steeringVelocity.Enabled = false
	steeringVelocity.Parent = root

	local stabilityTorque = Instance.new("Torque")
	stabilityTorque.Name = "StabilityTorque"
	stabilityTorque.Attachment0 = center
	stabilityTorque.RelativeTo = Enum.ActuatorRelativeTo.World
	stabilityTorque.Torque = Vector3.zero
	stabilityTorque.Parent = root
end

local function makeWheels(root: BasePart, model: Model)
	for wheelName, suspensionOffset in VehicleConfig.Chassis.SuspensionOffsets do
		local attachment = Instance.new("Attachment")
		attachment.Name = `Suspension{wheelName}`
		attachment.Position = suspensionOffset
		attachment.Parent = root

		local suspensionForce = Instance.new("VectorForce")
		suspensionForce.Name = `SuspensionForce{wheelName}`
		suspensionForce.Attachment0 = attachment
		suspensionForce.RelativeTo = Enum.ActuatorRelativeTo.World
		suspensionForce.ApplyAtCenterOfMass = false
		suspensionForce.Force = Vector3.zero
		suspensionForce.Parent = root

		local wheelOffset = VehicleConfig.Chassis.WheelOffsets[wheelName]
		local wheel = makePart(
			`Wheel{wheelName}`,
			Vector3.new(
				VehicleConfig.Chassis.WheelWidth,
				VehicleConfig.Chassis.WheelRadius * 2,
				VehicleConfig.Chassis.WheelRadius * 2
			),
			root.CFrame * CFrame.new(wheelOffset),
			Color3.fromRGB(25, 27, 31),
			Enum.Material.Rubber,
			model
		)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Anchored = false
		wheel.Massless = true
		wheel.CanCollide = false
		wheel.CanTouch = false
		wheel.CanQuery = false

		local wheelMotor = Instance.new("Motor6D")
		wheelMotor.Name = `WheelMotor{wheelName}`
		wheelMotor.Part0 = root
		wheelMotor.Part1 = wheel
		wheelMotor.C0 = CFrame.new(wheelOffset)
		wheelMotor.C1 = CFrame.identity
		wheelMotor.Parent = root
	end
end

local function makeSeats(root: BasePart, model: Model): (VehicleSeat, Seat)
	local driverSeat = Instance.new("VehicleSeat")
	driverSeat.Name = "DriverSeat"
	driverSeat.Size = Vector3.new(2, 1, 2)
	driverSeat.CFrame = root.CFrame * CFrame.new(-1.7, 2.15, 0.65)
	driverSeat.Color = Color3.fromRGB(35, 39, 46)
	driverSeat.Material = Enum.Material.SmoothPlastic
	driverSeat.HeadsUpDisplay = false
	driverSeat.MaxSpeed = 0
	driverSeat.Torque = 0
	driverSeat.TurnSpeed = 0
	driverSeat.Parent = model
	weldToRoot(root, driverSeat)

	local passengerSeat = Instance.new("Seat")
	passengerSeat.Name = "PassengerSeat"
	passengerSeat.Size = Vector3.new(2, 1, 2)
	passengerSeat.CFrame = root.CFrame * CFrame.new(1.7, 2.15, 0.65)
	passengerSeat.Color = Color3.fromRGB(35, 39, 46)
	passengerSeat.Material = Enum.Material.SmoothPlastic
	passengerSeat.Parent = model
	weldToRoot(root, passengerSeat)

	return driverSeat, passengerSeat
end

local function createStarterCar(spawnCFrame: CFrame, parent: Instance): VehicleRecord
	local model = Instance.new("Model")
	model.Name = VehicleConfig.ModelName
	model:SetAttribute(VehicleConfig.Attributes.IsVehicle, true)
	model:SetAttribute(VehicleConfig.Attributes.DriverUserId, 0)
	model:SetAttribute(VehicleConfig.Attributes.Health, VehicleConfig.Health.Maximum)
	model:SetAttribute(VehicleConfig.Attributes.MaxHealth, VehicleConfig.Health.Maximum)
	model:SetAttribute(VehicleConfig.Attributes.Disabled, false)
	model:SetAttribute(VehicleConfig.Attributes.Parked, true)
	model.Parent = parent

	local root = makePart(
		"ChassisRoot",
		VehicleConfig.Chassis.RootSize,
		spawnCFrame,
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		model
	)
	root.Anchored = true
	root.Transparency = 1
	root.CanCollide = true
	root.CanTouch = true
	root.CanQuery = true
	root.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.35, 0, 1, 1)
	model.PrimaryPart = root

	makeCenterActuators(root)
	makeWheels(root, model)

	local red = Color3.fromRGB(222, 55, 58)
	local darkRed = Color3.fromRGB(154, 34, 43)
	makeVisualPart(root, "LowerBody", Vector3.new(7.8, 1.6, 11.4), CFrame.new(0, 1.15, 0), red, Enum.Material.SmoothPlastic, model)
	makeVisualPart(root, "Hood", Vector3.new(7.2, 1, 3.8), CFrame.new(0, 2.1, -3.7), darkRed, Enum.Material.SmoothPlastic, model)
	makeVisualPart(root, "Trunk", Vector3.new(7.2, 1, 2.4), CFrame.new(0, 2, 4.45), darkRed, Enum.Material.SmoothPlastic, model)
	makeVisualPart(root, "Roof", Vector3.new(6.9, 0.5, 5.1), CFrame.new(0, 4.45, 0.6), red, Enum.Material.SmoothPlastic, model)
	makeVisualPart(root, "LeftPillar", Vector3.new(0.35, 2.4, 5), CFrame.new(-3.3, 3.2, 0.6), darkRed, Enum.Material.Metal, model)
	makeVisualPart(root, "RightPillar", Vector3.new(0.35, 2.4, 5), CFrame.new(3.3, 3.2, 0.6), darkRed, Enum.Material.Metal, model)

	local windshield = makeVisualPart(root, "Windshield", Vector3.new(6.3, 1.7, 0.25), CFrame.new(0, 3.55, -2.05) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(119, 206, 234), Enum.Material.Glass, model)
	windshield.Transparency = 0.25
	local rearWindow = makeVisualPart(root, "RearWindow", Vector3.new(6.3, 1.6, 0.25), CFrame.new(0, 3.45, 3.1) * CFrame.Angles(math.rad(18), 0, 0), Color3.fromRGB(119, 206, 234), Enum.Material.Glass, model)
	rearWindow.Transparency = 0.25

	makeVisualPart(root, "FrontBumper", Vector3.new(7.9, 0.55, 0.6), CFrame.new(0, 0.7, -6.15), Color3.fromRGB(55, 58, 64), Enum.Material.Metal, model)
	makeVisualPart(root, "RearBumper", Vector3.new(7.9, 0.55, 0.6), CFrame.new(0, 0.7, 6.15), Color3.fromRGB(55, 58, 64), Enum.Material.Metal, model)
	makeVisualPart(root, "LeftHeadlight", Vector3.new(1.7, 0.7, 0.2), CFrame.new(-2.25, 1.6, -5.77), Color3.fromRGB(255, 242, 176), Enum.Material.Neon, model)
	makeVisualPart(root, "RightHeadlight", Vector3.new(1.7, 0.7, 0.2), CFrame.new(2.25, 1.6, -5.77), Color3.fromRGB(255, 242, 176), Enum.Material.Neon, model)

	local driverSeat, passengerSeat = makeSeats(root, model)
	local _, driverPrompt = makePromptAnchor(root, "DriverDoorPrompt", Vector3.new(-4.6, 1.7, 0.5), "Drive", model)
	local _, passengerPrompt = makePromptAnchor(root, "PassengerDoorPrompt", Vector3.new(4.6, 1.7, 0.5), "Ride", model)
	passengerPrompt.KeyboardKeyCode = Enum.KeyCode.R

	root.Anchored = false
	local canSetOwnership = root:CanSetNetworkOwnership()
	if canSetOwnership then
		root:SetNetworkOwner(nil)
	end

	return {
		Model = model,
		Root = root,
		DriverSeat = driverSeat,
		PassengerSeat = passengerSeat,
		DriverPrompt = driverPrompt,
		PassengerPrompt = passengerPrompt,
		LastSafeCFrame = root.CFrame,
	}
end

local function getPlayerHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return humanoid
end

local function playerIsNear(player: Player, root: BasePart): boolean
	local character = player.Character
	local humanoidRootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return humanoidRootPart ~= nil
		and humanoidRootPart:IsA("BasePart")
		and (humanoidRootPart.Position - root.Position).Magnitude
			<= VehicleConfig.Interaction.PromptDistance + 3
end

local function clearAssignmentForSeat(seat: VehicleSeatType)
	for player, assignment in seatAssignments do
		if assignment.Seat == seat then
			seatAssignments[player] = nil
			lastExitTimes[player] = os.clock()
		end
	end
end

local function setNetworkOwner(record: VehicleRecord, player: Player?)
	if not record.Root:IsDescendantOf(Workspace) then
		return
	end
	local canSetOwnership, reason = record.Root:CanSetNetworkOwnership()
	if not canSetOwnership then
		warn(`Cannot set network ownership for {record.Model:GetFullName()}: {reason}`)
		return
	end
	record.Root:SetNetworkOwner(player)
end

local function updateDriver(record: VehicleRecord)
	clearAssignmentForSeat(record.DriverSeat)
	local humanoid = record.DriverSeat.Occupant
	local player = if humanoid and humanoid.Parent then Players:GetPlayerFromCharacter(humanoid.Parent) else nil

	if player then
		seatAssignments[player] = { Record = record, Seat = record.DriverSeat }
		record.Model:SetAttribute(VehicleConfig.Attributes.DriverUserId, player.UserId)
		record.DriverPrompt.Enabled = false
		setNetworkOwner(record, player)
	else
		record.Model:SetAttribute(VehicleConfig.Attributes.DriverUserId, 0)
		record.Model:SetAttribute(VehicleConfig.Attributes.Parked, true)
		record.DriverPrompt.Enabled = true
		VehicleDynamics.ResetForces(record.Model)
		-- Remove client-owned steering momentum before returning the empty car to
		-- server ownership. Linear momentum is still handled by parking drag.
		record.Root.AssemblyAngularVelocity = Vector3.zero
		setNetworkOwner(record, nil)
	end
end

local function updatePassenger(record: VehicleRecord)
	clearAssignmentForSeat(record.PassengerSeat)
	local humanoid = record.PassengerSeat.Occupant
	local player = if humanoid and humanoid.Parent then Players:GetPlayerFromCharacter(humanoid.Parent) else nil

	if player then
		seatAssignments[player] = { Record = record, Seat = record.PassengerSeat }
		record.PassengerPrompt.Enabled = false
	else
		record.PassengerPrompt.Enabled = true
	end
end

local function trySeatPlayer(player: Player, record: VehicleRecord, seat: VehicleSeatType, prompt: ProximityPrompt)
	if seat.Occupant or not playerIsNear(player, record.Root) then
		return
	end
	local rentalOwnerUserId = record.Model:GetAttribute("RentalOwnerUserId")
	if seat == record.DriverSeat
		and typeof(rentalOwnerUserId) == "number"
		and rentalOwnerUserId > 0
		and rentalOwnerUserId ~= player.UserId
	then
		return
	end
	if seatAssignments[player] then
		return
	end
	if os.clock() - (lastExitTimes[player] or 0) < VehicleConfig.Interaction.ExitCooldown then
		return
	end

	local humanoid = getPlayerHumanoid(player)
	if not humanoid or humanoid.SeatPart then
		return
	end

	prompt.Enabled = false
	seat:Sit(humanoid)
	task.delay(0.5, function()
		if seat.Parent and not seat.Occupant then
			prompt.Enabled = true
		end
	end)
end

local function findSafeExitCFrame(record: VehicleRecord, character: Model): CFrame
	local root = record.Root
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { record.Model, character }
	raycastParams.IgnoreWater = true
	raycastParams.RespectCanCollide = true

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { record.Model, character }

	local offsets = {
		Vector3.new(-7, 0, 0),
		Vector3.new(7, 0, 0),
		Vector3.new(0, 0, 8),
	}

	for _, offset in offsets do
		local sidePosition = root.CFrame:PointToWorldSpace(offset)
		local groundResult = Workspace:Raycast(
			sidePosition + Vector3.new(0, 8, 0),
			Vector3.new(0, -20, 0),
			raycastParams
		)
		local exitPosition = if groundResult then groundResult.Position + Vector3.new(0, 3.2, 0) else sidePosition + Vector3.new(0, 3, 0)
		local blockingParts = Workspace:GetPartBoundsInBox(CFrame.new(exitPosition), Vector3.new(3, 5, 3), overlapParams)
		local blocked = false
		for _, part in blockingParts do
			if part.CanCollide then
				blocked = true
				break
			end
		end
		if not blocked then
			local facing = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
			return CFrame.lookAt(exitPosition, exitPosition + facing)
		end
	end

	return root.CFrame * CFrame.new(-7, 4, 0)
end

local function exitVehicle(player: Player, forced: boolean?): boolean
	local assignment = seatAssignments[player]
	if not assignment then
		return false
	end
	local now = os.clock()
	if not forced and now - (lastExitTimes[player] or 0) < VehicleConfig.Interaction.ExitCooldown then
		return false
	end
	lastExitTimes[player] = now

	local humanoid = getPlayerHumanoid(player)
	if not humanoid or assignment.Seat.Occupant ~= humanoid then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local exitCFrame = findSafeExitCFrame(assignment.Record, character)
	assignment.Record.Model:SetAttribute(VehicleConfig.Attributes.Parked, true)
	humanoid.Sit = false
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	if forced then
		return true
	end
	task.defer(function()
		RunService.Heartbeat:Wait()
		if character.Parent then
			character:PivotTo(exitCFrame)
		end
	end)
	return true
end

local function setVehicleParked(player: Player, requestedParked: unknown)
	if typeof(requestedParked) ~= "boolean" then
		return
	end
	local now = os.clock()
	if now - (lastParkRequestTimes[player] or 0) < 0.1 then
		return
	end
	lastParkRequestTimes[player] = now
	local assignment = seatAssignments[player]
	if not assignment or assignment.Seat ~= assignment.Record.DriverSeat then
		return
	end
	if assignment.Record.DriverSeat.Occupant ~= getPlayerHumanoid(player) then
		return
	end
	assignment.Record.Model:SetAttribute(VehicleConfig.Attributes.Parked, requestedParked)
end

local function vectorIsFinite(vector: Vector3): boolean
	return vector.X == vector.X
		and vector.Y == vector.Y
		and vector.Z == vector.Z
		and math.abs(vector.X) < math.huge
		and math.abs(vector.Y) < math.huge
		and math.abs(vector.Z) < math.huge
end

local function validateVehicle(record: VehicleRecord)
	local root = record.Root
	local position = root.Position
	local horizontalSpeed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
	local maximumCoordinate = VehicleConfig.Security.MaximumWorldCoordinate
	local withinWorld = math.abs(position.X) <= maximumCoordinate
		and math.abs(position.Y) <= maximumCoordinate
		and math.abs(position.Z) <= maximumCoordinate
	local plausibleSpeed = horizontalSpeed
		<= VehicleConfig.Handling.MaximumForwardSpeed
			* VehicleConfig.Security.MaximumPlausibleSpeedMultiplier

	if vectorIsFinite(position) and withinWorld and plausibleSpeed then
		record.LastSafeCFrame = root.CFrame
		return
	end

	warn(`Resetting {record.Model.Name} after impossible physics state`)
	setNetworkOwner(record, nil)
	record.Model:PivotTo(record.LastSafeCFrame + Vector3.new(0, 2, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local occupant = record.DriverSeat.Occupant
	local player = if occupant and occupant.Parent then Players:GetPlayerFromCharacter(occupant.Parent) else nil
	if player then
		task.defer(function()
			if record.Model.Parent and record.DriverSeat.Occupant == occupant then
				setNetworkOwner(record, player)
			end
		end)
	end
end

local function registerVehicle(record: VehicleRecord)
	records[record.Model] = record
	record.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		updateDriver(record)
	end)
	record.PassengerSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		updatePassenger(record)
	end)
	record.DriverPrompt.Triggered:Connect(function(player)
		trySeatPlayer(player, record, record.DriverSeat, record.DriverPrompt)
	end)
	record.PassengerPrompt.Triggered:Connect(function(player)
		trySeatPlayer(player, record, record.PassengerSeat, record.PassengerPrompt)
	end)

	updateDriver(record)
	updatePassenger(record)
end

function VehicleService.DamageVehicle(vehicle: Model, amount: number): number
	assert(records[vehicle], "DamageVehicle received an unregistered vehicle")
	assert(amount >= 0, "Vehicle damage must be non-negative")

	local currentHealth = vehicle:GetAttribute(VehicleConfig.Attributes.Health)
	local health = if typeof(currentHealth) == "number" then currentHealth else VehicleConfig.Health.Maximum
	local newHealth = math.clamp(health - amount, 0, VehicleConfig.Health.Maximum)
	vehicle:SetAttribute(VehicleConfig.Attributes.Health, newHealth)
	if newHealth <= 0 then
		vehicle:SetAttribute(VehicleConfig.Attributes.Disabled, true)
		VehicleDynamics.ResetForces(vehicle)
	end
	return newHealth
end

function VehicleService.ForceExit(player: Player): boolean
	return exitVehicle(player, true)
end

function VehicleService.CreateRentalVehicle(spawnCFrame: CFrame, parent: Instance, owner: Player): Model
	assert(started, "VehicleService must be started before creating rental vehicles")
	assert(owner.Parent == Players, "Rental owner must be an active player")
	local record = createStarterCar(spawnCFrame, parent)
	record.Model.Name = `RentalGleepGlorp_{owner.UserId}`
	record.Model:SetAttribute("IsRentalVehicle", true)
	record.Model:SetAttribute("RentalOwnerUserId", owner.UserId)
	registerVehicle(record)
	return record.Model
end

function VehicleService.DestroyPlayerVehicle(vehicle: Model)
	local record = records[vehicle]
	if not record or npcVehicles[vehicle] then
		return
	end
	for player, assignment in seatAssignments do
		if assignment.Record == record then
			local humanoid = assignment.Seat.Occupant
			if humanoid then
				humanoid.Sit = false
			end
			seatAssignments[player] = nil
		end
	end
	records[vehicle] = nil
	vehicle:Destroy()
end

local function markPoliceVisual(part: BasePart)
	part:SetAttribute("PoliceDriverVisual", true)
end

function VehicleService.CreatePoliceVehicle(spawnCFrame: CFrame, parent: Instance): Model
	assert(started, "VehicleService must be started before creating NPC vehicles")

	local record = createStarterCar(spawnCFrame, parent)
	local vehicle = record.Model
	vehicle.Name = "PoliceCruiser"
	vehicle:SetAttribute("IsPoliceVehicle", true)
	vehicle:SetAttribute("PoliceTargetUserId", 0)

	local driverAnchor = record.DriverPrompt.Parent
	if driverAnchor then
		driverAnchor:Destroy()
	end
	local passengerAnchor = record.PassengerPrompt.Parent
	if passengerAnchor then
		passengerAnchor:Destroy()
	end

	local white = Color3.fromRGB(232, 236, 242)
	local navy = Color3.fromRGB(35, 75, 135)
	for _, descendant in vehicle:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant.Name == "LowerBody" or descendant.Name == "Roof" then
				descendant.Color = white
			elseif descendant.Name == "Hood"
				or descendant.Name == "Trunk"
				or descendant.Name == "LeftPillar"
				or descendant.Name == "RightPillar"
			then
				descendant.Color = navy
			end
		end
	end

	local redLight = makeVisualPart(
		record.Root,
		"SirenRed",
		Vector3.new(2.2, 0.45, 1),
		CFrame.new(-1.2, 4.95, 0.6),
		Color3.fromRGB(255, 55, 55),
		Enum.Material.Neon,
		vehicle
	)
	redLight:SetAttribute("PoliceSirenLight", "Red")
	local blueLight = makeVisualPart(
		record.Root,
		"SirenBlue",
		Vector3.new(2.2, 0.45, 1),
		CFrame.new(1.2, 4.95, 0.6),
		Color3.fromRGB(55, 135, 255),
		Enum.Material.Neon,
		vehicle
	)
	blueLight:SetAttribute("PoliceSirenLight", "Blue")

	local torso = makeVisualPart(record.Root, "PoliceDriverTorso", Vector3.new(1.8, 2, 1), CFrame.new(-1.7, 3.25, 0.65), navy, Enum.Material.SmoothPlastic, vehicle)
	local head = makeVisualPart(record.Root, "PoliceDriverHead", Vector3.new(1.4, 1.4, 1.4), CFrame.new(-1.7, 4.85, 0.65), Color3.fromRGB(241, 190, 145), Enum.Material.SmoothPlastic, vehicle)
	local cap = makeVisualPart(record.Root, "PoliceDriverCap", Vector3.new(1.7, 0.35, 1.7), CFrame.new(-1.7, 5.55, 0.65), navy, Enum.Material.SmoothPlastic, vehicle)
	markPoliceVisual(torso)
	markPoliceVisual(head)
	markPoliceVisual(cap)

	npcVehicles[vehicle] = true
	local canSetOwnership = record.Root:CanSetNetworkOwnership()
	if canSetOwnership then
		record.Root:SetNetworkOwner(nil)
	end
	return vehicle
end

function VehicleService.StepNpcVehicle(
	vehicle: Model,
	controls: VehicleDynamics.ControlState,
	deltaTime: number
): number
	assert(npcVehicles[vehicle] == true, "StepNpcVehicle received an unknown NPC vehicle")
	return VehicleDynamics.Step(vehicle, controls, deltaTime)
end

function VehicleService.SetNpcDriverVisible(vehicle: Model, visible: boolean)
	if not npcVehicles[vehicle] then
		return
	end
	for _, descendant in vehicle:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:GetAttribute("PoliceDriverVisual") == true then
			descendant.Transparency = if visible then 0 else 1
		end
	end
end

function VehicleService.DestroyNpcVehicle(vehicle: Model)
	if not npcVehicles[vehicle] then
		return
	end
	npcVehicles[vehicle] = nil
	vehicle:Destroy()
end

function VehicleService.Start()
	assert(not started, "VehicleService.Start may only be called once")
	started = true

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local existingRemote = remotes:FindFirstChild("ExitVehicle")
	if existingRemote then
		assert(existingRemote:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.ExitVehicle must be a RemoteEvent")
		exitVehicleRemote = existingRemote
	else
		exitVehicleRemote = Instance.new("RemoteEvent")
		exitVehicleRemote.Name = "ExitVehicle"
		exitVehicleRemote.Parent = remotes
	end
	exitVehicleRemote.OnServerEvent:Connect(function(player)
		exitVehicle(player, false)
	end)

	local existingParkRemote = remotes:FindFirstChild("SetVehicleParked")
	if existingParkRemote then
		assert(existingParkRemote:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.SetVehicleParked must be a RemoteEvent")
		setVehicleParkedRemote = existingParkRemote
	else
		setVehicleParkedRemote = Instance.new("RemoteEvent")
		setVehicleParkedRemote.Name = "SetVehicleParked"
		setVehicleParkedRemote.Parent = remotes
	end
	setVehicleParkedRemote.OnServerEvent:Connect(setVehicleParked)

	local world = Workspace:WaitForChild("GameWorld")
	local vehiclesFolder = Instance.new("Folder")
	vehiclesFolder.Name = "Vehicles"
	vehiclesFolder.Parent = world

	Players.PlayerRemoving:Connect(function(player)
		local assignment = seatAssignments[player]
		if assignment then
			local humanoid = assignment.Seat.Occupant
			if humanoid then
				humanoid.Sit = false
			end
			seatAssignments[player] = nil
		end
		lastExitTimes[player] = nil
		lastParkRequestTimes[player] = nil
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		for _, record in records do
			local driverHumanoid = record.DriverSeat.Occupant
			local driver = if driverHumanoid and driverHumanoid.Parent
				then Players:GetPlayerFromCharacter(driverHumanoid.Parent)
				else nil
			if not driver then
				VehicleDynamics.Step(record.Model, IDLE_CONTROLS, deltaTime)
			end
			validateVehicle(record)
		end
	end)
end

return table.freeze(VehicleService)
