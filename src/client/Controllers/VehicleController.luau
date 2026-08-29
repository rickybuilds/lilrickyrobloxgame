--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local VehicleConfig = require(ReplicatedStorage.Shared.Config.VehicleConfig)
local VehicleDynamics = require(ReplicatedStorage.Shared.Vehicle.VehicleDynamics)
local VehicleHudController = require(script.Parent.VehicleHudController)

local VehicleController = {}
local player = Players.LocalPlayer
local exitVehicleRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ExitVehicle") :: RemoteEvent
local setVehicleParkedRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SetVehicleParked") :: RemoteEvent

local HANDBRAKE_ACTION = "VehicleHandbrake"
local EXIT_ACTION = "ExitVehicle"
local PARK_ACTION = "ParkVehicle"
local ACTION_PRIORITY = Enum.ContextActionPriority.High.Value + 10

local activeVehicle: Model? = nil
local activeDriverSeat: VehicleSeat? = nil
local handbrake = false
local seatActionsBound = false
local driverActionsBound = false
local started = false
local smoothedThrottle = 0
local smoothedSteering = 0
local lastParkRequest = 0

local function findVehicleFromSeat(seatPart: BasePart): Model?
	local current: Instance? = seatPart
	while current do
		if current:IsA("Model") and current:GetAttribute(VehicleConfig.Attributes.IsVehicle) == true then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function setSeatPromptsVisible(vehicle: Model, visible: boolean)
	for _, descendant in vehicle:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "SeatPrompt" then
			if not visible then
				descendant.Enabled = false
			else
				local promptAnchor = descendant.Parent
				local seatName = if promptAnchor and promptAnchor.Name == "DriverDoorPrompt"
					then "DriverSeat"
					elseif promptAnchor and promptAnchor.Name == "PassengerDoorPrompt"
					then "PassengerSeat"
					else nil
				local seat = if seatName then vehicle:FindFirstChild(seatName) else nil
				descendant.Enabled = seat ~= nil
					and (seat:IsA("Seat") or seat:IsA("VehicleSeat"))
					and seat.Occupant == nil
			end
		end
	end
end

local function handleExit(
	_actionName: string,
	inputState: Enum.UserInputState,
	_inputObject: InputObject
): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin then
		exitVehicleRemote:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

local function handleHandbrake(
	_actionName: string,
	inputState: Enum.UserInputState,
	_inputObject: InputObject
): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin then
		handbrake = true
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		handbrake = false
	end
	return Enum.ContextActionResult.Sink
end

local function handlePark(
	_actionName: string,
	inputState: Enum.UserInputState,
	_inputObject: InputObject
): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin and activeVehicle then
		local parked = activeVehicle:GetAttribute(VehicleConfig.Attributes.Parked) == true
		setVehicleParkedRemote:FireServer(not parked)
		lastParkRequest = os.clock()
	end
	return Enum.ContextActionResult.Sink
end

local function unbindActions()
	if driverActionsBound then
		ContextActionService:UnbindAction(HANDBRAKE_ACTION)
		ContextActionService:UnbindAction(PARK_ACTION)
		driverActionsBound = false
	end
	if seatActionsBound then
		ContextActionService:UnbindAction(EXIT_ACTION)
		seatActionsBound = false
	end
	handbrake = false
	smoothedThrottle = 0
	smoothedSteering = 0
end

local function bindActions(isDriver: boolean)
	unbindActions()
	ContextActionService:BindActionAtPriority(
		EXIT_ACTION,
		handleExit,
		true,
		ACTION_PRIORITY,
		Enum.KeyCode.ButtonB
	)
	ContextActionService:SetTitle(EXIT_ACTION, "EXIT")
	ContextActionService:SetPosition(EXIT_ACTION, UDim2.new(1, -108, 1, -120))
	seatActionsBound = true

	if isDriver then
		ContextActionService:BindActionAtPriority(
			HANDBRAKE_ACTION,
			handleHandbrake,
			true,
			ACTION_PRIORITY,
			Enum.KeyCode.Space,
			Enum.KeyCode.ButtonX
		)
		ContextActionService:SetTitle(HANDBRAKE_ACTION, "BRAKE")
		ContextActionService:SetPosition(HANDBRAKE_ACTION, UDim2.new(1, -220, 1, -120))
		ContextActionService:BindActionAtPriority(
			PARK_ACTION,
			handlePark,
			true,
			ACTION_PRIORITY,
			Enum.KeyCode.P,
			Enum.KeyCode.ButtonY
		)
		ContextActionService:SetTitle(PARK_ACTION, "PARK")
		ContextActionService:SetPosition(PARK_ACTION, UDim2.new(1, -332, 1, -120))
		driverActionsBound = true
	end
end

local function stopDriving()
	local previousVehicle = activeVehicle
	if previousVehicle then
		VehicleDynamics.ResetForces(previousVehicle)
		setSeatPromptsVisible(previousVehicle, true)
	end
	activeVehicle = nil
	activeDriverSeat = nil
	VehicleHudController.SetVisible(false)
	VehicleHudController.SetPassengerVisible(false)
	unbindActions()
end

local function handleSeated(active: boolean, seatPart: BasePart?)
	if not active or not seatPart then
		stopDriving()
		return
	end

	local vehicle = findVehicleFromSeat(seatPart)
	if not vehicle then
		stopDriving()
		return
	end

	activeVehicle = vehicle
	setSeatPromptsVisible(vehicle, false)
	if seatPart:IsA("VehicleSeat") and seatPart.Name == "DriverSeat" then
		activeDriverSeat = seatPart
		VehicleHudController.SetPassengerVisible(false)
		VehicleHudController.SetVisible(true)
		bindActions(true)
	else
		activeDriverSeat = nil
		VehicleHudController.SetVisible(false)
		VehicleHudController.SetPassengerVisible(true)
		bindActions(false)
	end
end

local function connectCharacter(character: Model)
	stopDriving()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Seated:Connect(handleSeated)
	local currentSeat = humanoid.SeatPart
	if currentSeat and (currentSeat:IsA("Seat") or currentSeat:IsA("VehicleSeat")) then
		handleSeated(true, currentSeat)
	end
end

function VehicleController.Start()
	assert(not started, "VehicleController.Start may only be called once")
	started = true

	player.CharacterAdded:Connect(connectCharacter)
	if player.Character then
		connectCharacter(player.Character)
	end
	UserInputService.InputBegan:Connect(function(inputObject)
		if inputObject.KeyCode == Enum.KeyCode.E
			and activeVehicle
			and UserInputService:GetFocusedTextBox() == nil
		then
			exitVehicleRemote:FireServer()
		end
	end)

	RunService.PreSimulation:Connect(function(deltaTime)
		local vehicle = activeVehicle
		local driverSeat = activeDriverSeat
		if not vehicle or not driverSeat or not vehicle.Parent or not driverSeat.Parent then
			return
		end

		local rawThrottle = driverSeat.ThrottleFloat
		local rawSteering = driverSeat.SteerFloat
		smoothedThrottle += (rawThrottle - smoothedThrottle)
			* math.clamp(deltaTime * VehicleConfig.Input.ThrottleResponse, 0, 1)
		smoothedSteering += (rawSteering - smoothedSteering)
			* math.clamp(deltaTime * VehicleConfig.Input.SteeringResponse, 0, 1)

		local controls: VehicleDynamics.ControlState = {
			Throttle = smoothedThrottle,
			Steering = smoothedSteering,
			Brake = 0,
			Handbrake = handbrake,
			Parked = vehicle:GetAttribute(VehicleConfig.Attributes.Parked) == true,
		}
		if controls.Parked and math.abs(rawThrottle) > 0.1 and os.clock() - lastParkRequest > 0.5 then
			setVehicleParkedRemote:FireServer(false)
			lastParkRequest = os.clock()
		end
		local speed = VehicleDynamics.Step(vehicle, controls, deltaTime)
		local root = vehicle:FindFirstChild("ChassisRoot")
		if not root or not root:IsA("BasePart") then
			return
		end
		local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		local forwardSpeed = if forward.Magnitude > 0.001
			then Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z):Dot(forward.Unit)
			else 0
		local rawHealth = vehicle:GetAttribute(VehicleConfig.Attributes.Health)
		local rawMaximumHealth = vehicle:GetAttribute(VehicleConfig.Attributes.MaxHealth)
		local health = if typeof(rawHealth) == "number" then rawHealth else VehicleConfig.Health.Maximum
		local maximumHealth = if typeof(rawMaximumHealth) == "number" then rawMaximumHealth else VehicleConfig.Health.Maximum
		VehicleHudController.Update(speed, forwardSpeed, health, maximumHealth, handbrake, controls.Parked)
	end)
end

return table.freeze(VehicleController)
