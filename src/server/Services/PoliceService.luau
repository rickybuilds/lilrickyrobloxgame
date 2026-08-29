--!strict

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PoliceConfig = require(ReplicatedStorage.Shared.Config.PoliceConfig)
local VehicleDynamics = require(ReplicatedStorage.Shared.Vehicle.VehicleDynamics)
local ArrestService = require(script.Parent.ArrestService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local VehicleService = require(script.Parent.VehicleService)
local WantedService = require(script.Parent.WantedService)

local PoliceService = {}
local started = false

type UnitState = "VehiclePursuit" | "FootPursuit" | "ReturningToVehicle"

type PoliceUnit = {
	Target: Player,
	State: UnitState,
	Vehicle: Model,
	VehicleRoot: BasePart,
	SpawnMarker: BasePart,
	Officer: Model?,
	OfficerHumanoid: Humanoid?,
	OfficerRoot: BasePart?,
	PathBusy: boolean,
	PathWaypoints: { PathWaypoint },
	WaypointIndex: number,
	LastPathRequest: number,
	ArrestStartedAt: number?,
	LastProgressPosition: Vector3,
	LastProgressAt: number,
	ReverseUntil: number,
	AvoidanceSign: number,
	RaycastParams: RaycastParams,
}

local unitsByPlayer: { [Player]: PoliceUnit } = {}
local reservedMarkers: { [BasePart]: Player } = {}
local responseMarkers: { BasePart } = {}
local lastDispatchAttempt: { [Player]: number } = {}

local PARKED_CONTROLS: VehicleDynamics.ControlState = {
	Throttle = 0,
	Steering = 0,
	Brake = 1,
	Handbrake = true,
	Parked = true,
}

local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function getLivingTarget(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return character, humanoid, nil
	end
	return character, humanoid, root
end

local function makeOfficerPart(
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	color: Color3,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = root.CFrame * localCFrame
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function createOfficer(spawnCFrame: CFrame, parent: Instance): (Model, Humanoid, BasePart)
	local officer = Instance.new("Model")
	officer.Name = "PoliceOfficer"
	officer.Parent = parent

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	-- The root is a simple invisible arcade collision capsule. Decorative body
	-- parts are welded and non-collidable so they cannot snag on map geometry.
	root.Size = Vector3.new(2, 5, 2)
	root.CFrame = spawnCFrame
	root.Transparency = 1
	root.CanCollide = true
	root.CanTouch = false
	root.Parent = officer
	officer.PrimaryPart = root

	local navy = Color3.fromRGB(34, 70, 125)
	local skin = Color3.fromRGB(241, 190, 145)
	makeOfficerPart(root, "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), navy, officer)
	makeOfficerPart(root, "Head", Vector3.new(1.5, 1.5, 1.5), CFrame.new(0, 1.75, 0), skin, officer)
	makeOfficerPart(root, "LeftArm", Vector3.new(0.8, 2, 0.8), CFrame.new(-1.45, 0, 0), navy, officer)
	makeOfficerPart(root, "RightArm", Vector3.new(0.8, 2, 0.8), CFrame.new(1.45, 0, 0), navy, officer)
	makeOfficerPart(root, "LeftLeg", Vector3.new(0.85, 2, 0.85), CFrame.new(-0.55, -2, 0), Color3.fromRGB(28, 36, 52), officer)
	makeOfficerPart(root, "RightLeg", Vector3.new(0.85, 2, 0.85), CFrame.new(0.55, -2, 0), Color3.fromRGB(28, 36, 52), officer)
	makeOfficerPart(root, "PoliceCap", Vector3.new(1.8, 0.35, 1.8), CFrame.new(0, 2.55, 0), navy, officer)

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = "Officer"
	humanoid.WalkSpeed = PoliceConfig.Officer.WalkSpeed
	humanoid.HipHeight = 0
	humanoid.AutoRotate = true
	humanoid.RequiresNeck = false
	humanoid.Parent = officer

	local canSetOwnership = root:CanSetNetworkOwnership()
	if canSetOwnership then
		root:SetNetworkOwner(nil)
	end
	return officer, humanoid, root
end

local function setSirenLights(unit: PoliceUnit, now: number)
	local redVisible = math.floor(now * 5) % 2 == 0
	for _, descendant in unit.Vehicle:GetDescendants() do
		if descendant:IsA("BasePart") then
			local lightType = descendant:GetAttribute("PoliceSirenLight")
			if lightType == "Red" then
				descendant.Transparency = if redVisible then 0 else 0.65
			elseif lightType == "Blue" then
				descendant.Transparency = if redVisible then 0.65 else 0
			end
		end
	end
end

local function cleanupUnit(player: Player)
	local unit = unitsByPlayer[player]
	if not unit then
		return
	end

	unitsByPlayer[player] = nil
	reservedMarkers[unit.SpawnMarker] = nil
	if unit.Officer then
		unit.Officer:Destroy()
	end
	VehicleService.DestroyNpcVehicle(unit.Vehicle)
end

local function chooseResponseMarker(targetPosition: Vector3): BasePart?
	local bestMarker: BasePart? = nil
	local bestDistance = math.huge
	for _, marker in responseMarkers do
		if reservedMarkers[marker] == nil then
			local distance = horizontal(marker.Position - targetPosition).Magnitude
			if distance >= PoliceConfig.Dispatch.MinimumSpawnDistance and distance < bestDistance then
				bestDistance = distance
				bestMarker = marker
			end
		end
	end
	return bestMarker
end

local function ensureUnit(player: Player)
	if unitsByPlayer[player]
		or player.Parent ~= Players
		or WantedService.GetLevel(player) <= 0
		or ArrestService.IsArrested(player)
	then
		return
	end

	local _, _, targetRoot = getLivingTarget(player)
	if not targetRoot then
		return
	end
	local marker = chooseResponseMarker(targetRoot.Position)
	if not marker then
		return
	end

	local flatTarget = Vector3.new(targetRoot.Position.X, marker.Position.Y, targetRoot.Position.Z)
	local spawnCFrame = CFrame.lookAt(
		marker.Position + Vector3.new(0, 3.2, 0),
		flatTarget + Vector3.new(0, 3.2, 0)
	)
	local vehiclesFolder = marker:FindFirstAncestor(GameConfig.World.ContainerName):FindFirstChild("Vehicles")
	assert(vehiclesFolder, "PoliceService requires Workspace.GameWorld.Vehicles")
	local vehicle = VehicleService.CreatePoliceVehicle(spawnCFrame, vehiclesFolder)
	vehicle:SetAttribute(PoliceConfig.Attributes.TargetUserId, player.UserId)
	local vehicleRoot = vehicle.PrimaryPart
	assert(vehicleRoot and vehicleRoot:IsA("BasePart"), "Police vehicle requires a BasePart PrimaryPart")

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { vehicle, player.Character or vehicle }
	raycastParams.IgnoreWater = true
	raycastParams.RespectCanCollide = true

	local now = os.clock()
	local unit: PoliceUnit = {
		Target = player,
		State = "VehiclePursuit",
		Vehicle = vehicle,
		VehicleRoot = vehicleRoot,
		SpawnMarker = marker,
		Officer = nil,
		OfficerHumanoid = nil,
		OfficerRoot = nil,
		PathBusy = false,
		PathWaypoints = {},
		WaypointIndex = 1,
		LastPathRequest = 0,
		ArrestStartedAt = nil,
		LastProgressPosition = vehicleRoot.Position,
		LastProgressAt = now,
		ReverseUntil = 0,
		AvoidanceSign = if player.UserId % 2 == 0 then 1 else -1,
		RaycastParams = raycastParams,
	}
	unitsByPlayer[player] = unit
	reservedMarkers[marker] = player
	PlayerStateService.SetRobberyStatus(player, "Police dispatched from the station!")
end

local function findGroundCFrame(position: Vector3, exclusions: { Instance }): CFrame
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclusions
	params.IgnoreWater = true
	params.RespectCanCollide = true
	local result = Workspace:Raycast(position + Vector3.new(0, 12, 0), Vector3.new(0, -30, 0), params)
	local groundPosition = if result then result.Position else position
	return CFrame.new(groundPosition + Vector3.new(0, 3, 0))
end

local function dismountOfficer(unit: PoliceUnit)
	if unit.State ~= "VehiclePursuit" or unit.Officer then
		return
	end

	VehicleService.StepNpcVehicle(unit.Vehicle, PARKED_CONTROLS, 1 / 60)
	VehicleService.SetNpcDriverVisible(unit.Vehicle, false)
	local sidePosition = unit.VehicleRoot.CFrame:PointToWorldSpace(Vector3.new(-6, 0, 0))
	local officerCFrame = findGroundCFrame(sidePosition, { unit.Vehicle })
	local officer, humanoid, officerRoot = createOfficer(officerCFrame, unit.Vehicle.Parent)
	unit.Officer = officer
	unit.OfficerHumanoid = humanoid
	unit.OfficerRoot = officerRoot
	unit.State = "FootPursuit"
	unit.PathWaypoints = {}
	unit.WaypointIndex = 1
	unit.LastPathRequest = 0
	unit.ArrestStartedAt = nil
end

local function reboardOfficer(unit: PoliceUnit)
	if unit.Officer then
		unit.Officer:Destroy()
	end
	unit.Officer = nil
	unit.OfficerHumanoid = nil
	unit.OfficerRoot = nil
	unit.State = "VehiclePursuit"
	unit.PathWaypoints = {}
	unit.WaypointIndex = 1
	unit.PathBusy = false
	unit.ArrestStartedAt = nil
	VehicleService.SetNpcDriverVisible(unit.Vehicle, true)
end

local function requestOfficerPath(unit: PoliceUnit, destination: Vector3, now: number)
	if unit.PathBusy or now - unit.LastPathRequest < PoliceConfig.Officer.PathRefreshInterval then
		return
	end
	local officerRoot = unit.OfficerRoot
	if not officerRoot then
		return
	end

	unit.PathBusy = true
	unit.LastPathRequest = now
	local startPosition = officerRoot.Position
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			WaypointSpacing = 5,
		})
		local success = pcall(function()
			path:ComputeAsync(startPosition, destination)
		end)

		if unitsByPlayer[unit.Target] ~= unit then
			return
		end
		unit.PathBusy = false
		if success and path.Status == Enum.PathStatus.Success then
			unit.PathWaypoints = path:GetWaypoints()
			unit.WaypointIndex = math.min(2, #unit.PathWaypoints)
		else
			unit.PathWaypoints = {}
			unit.WaypointIndex = 1
		end
	end)
end

local function moveOfficer(unit: PoliceUnit, destination: Vector3, now: number)
	local humanoid = unit.OfficerHumanoid
	local officerRoot = unit.OfficerRoot
	if not humanoid or not officerRoot or humanoid.Health <= 0 then
		return
	end

	requestOfficerPath(unit, destination, now)
	local waypoint = unit.PathWaypoints[unit.WaypointIndex]
	if waypoint then
		if horizontal(waypoint.Position - officerRoot.Position).Magnitude
			<= PoliceConfig.Officer.WaypointReachedDistance
		then
			unit.WaypointIndex += 1
			waypoint = unit.PathWaypoints[unit.WaypointIndex]
		end
	end

	if waypoint then
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end
		humanoid:MoveTo(waypoint.Position)
	else
		humanoid:MoveTo(destination)
	end
end

local function updateVehiclePursuit(
	unit: PoliceUnit,
	targetCharacter: Model,
	targetHumanoid: Humanoid,
	targetRoot: BasePart,
	deltaTime: number,
	now: number
)
	local toTarget = horizontal(targetRoot.Position - unit.VehicleRoot.Position)
	local distance = toTarget.Magnitude
	if distance < 0.001 then
		VehicleService.StepNpcVehicle(unit.Vehicle, PARKED_CONTROLS, deltaTime)
		return
	end

	unit.RaycastParams.FilterDescendantsInstances = { unit.Vehicle, targetCharacter }
	local direction = toTarget.Unit
	local localDirection = unit.VehicleRoot.CFrame:VectorToObjectSpace(direction)
	local steering = math.clamp(localDirection.X * 2.2, -1, 1)
	local speed = horizontal(unit.VehicleRoot.AssemblyLinearVelocity).Magnitude
	local targetSpeed = horizontal(targetRoot.AssemblyLinearVelocity).Magnitude
	local targetSeated = targetHumanoid.SeatPart ~= nil
	local wantedLevel = WantedService.GetLevel(unit.Target)
	local speedLimit = PoliceConfig.Vehicle.ResponseSpeeds[wantedLevel]
		or PoliceConfig.Vehicle.ResponseSpeeds[GameConfig.Wanted.MaximumLevel]

	if horizontal(unit.VehicleRoot.Position - unit.LastProgressPosition).Magnitude >= 4 then
		unit.LastProgressPosition = unit.VehicleRoot.Position
		unit.LastProgressAt = now
	elseif now - unit.LastProgressAt >= PoliceConfig.Vehicle.StuckTime then
		unit.ReverseUntil = now + PoliceConfig.Vehicle.ReverseTime
		unit.AvoidanceSign *= -1
		unit.LastProgressAt = now
	end

	local throttle = 1
	local brake = 0
	if now < unit.ReverseUntil then
		throttle = -1
		steering = unit.AvoidanceSign
	elseif speed > speedLimit then
		throttle = 0
		brake = 1
	end

	local preparingToDismount = (not targetSeated and distance <= PoliceConfig.Vehicle.DismountDistance)
		or (targetSeated and targetSpeed <= PoliceConfig.Arrest.MaximumSuspectSpeed and distance <= 20)
	if preparingToDismount and distance <= PoliceConfig.Vehicle.ApproachSlowDistance then
		throttle = 0
		brake = 1
	end

	local obstacle = Workspace:Raycast(
		unit.VehicleRoot.Position + Vector3.new(0, 1, 0),
		unit.VehicleRoot.CFrame.LookVector * PoliceConfig.Vehicle.ObstacleCheckDistance,
		unit.RaycastParams
	)
	if obstacle and now >= unit.ReverseUntil then
		steering = unit.AvoidanceSign
		throttle = 0.35
	end

	local controls: VehicleDynamics.ControlState = {
		Throttle = throttle,
		Steering = steering,
		Brake = brake,
		Handbrake = false,
		Parked = false,
	}
	VehicleService.StepNpcVehicle(unit.Vehicle, controls, deltaTime)

	if preparingToDismount and speed <= 9 then
		dismountOfficer(unit)
	end
end

local function updateFootPursuit(
	unit: PoliceUnit,
	targetHumanoid: Humanoid,
	targetRoot: BasePart,
	deltaTime: number,
	now: number
)
	VehicleService.StepNpcVehicle(unit.Vehicle, PARKED_CONTROLS, deltaTime)
	local officerRoot = unit.OfficerRoot
	if not officerRoot then
		reboardOfficer(unit)
		return
	end

	local targetSeated = targetHumanoid.SeatPart ~= nil
	if unit.State == "FootPursuit" and targetSeated then
		unit.State = "ReturningToVehicle"
		unit.PathWaypoints = {}
	elseif unit.State == "ReturningToVehicle" and not targetSeated then
		unit.State = "FootPursuit"
		unit.PathWaypoints = {}
	end

	if unit.State == "ReturningToVehicle" then
		local vehiclePosition = unit.VehicleRoot.Position
		moveOfficer(unit, vehiclePosition, now)
		if horizontal(vehiclePosition - officerRoot.Position).Magnitude <= PoliceConfig.Officer.ReboardDistance then
			reboardOfficer(unit)
		end
		return
	end

	moveOfficer(unit, targetRoot.Position, now)
	local distance = horizontal(targetRoot.Position - officerRoot.Position).Magnitude
	local targetSpeed = horizontal(targetRoot.AssemblyLinearVelocity).Magnitude
	if distance <= PoliceConfig.Arrest.Distance
		and targetSpeed <= PoliceConfig.Arrest.MaximumSuspectSpeed
	then
		if not unit.ArrestStartedAt then
			unit.ArrestStartedAt = now
			PlayerStateService.SetRobberyStatus(unit.Target, "Police are making an arrest!")
		elseif now - unit.ArrestStartedAt >= PoliceConfig.Arrest.HoldDuration then
			if ArrestService.Arrest(unit.Target) then
				cleanupUnit(unit.Target)
			end
		end
	else
		unit.ArrestStartedAt = nil
	end
end

local function updateUnit(unit: PoliceUnit, deltaTime: number, now: number)
	if not unit.Vehicle.Parent then
		cleanupUnit(unit.Target)
		return
	end
	setSirenLights(unit, now)

	local targetCharacter, targetHumanoid, targetRoot = getLivingTarget(unit.Target)
	if not targetCharacter or not targetHumanoid or not targetRoot then
		VehicleService.StepNpcVehicle(unit.Vehicle, PARKED_CONTROLS, deltaTime)
		return
	end

	if unit.State == "VehiclePursuit" then
		updateVehiclePursuit(unit, targetCharacter, targetHumanoid, targetRoot, deltaTime, now)
	else
		updateFootPursuit(unit, targetHumanoid, targetRoot, deltaTime, now)
	end
end

local function watchPlayer(player: Player)
	player:GetAttributeChangedSignal(GameConfig.Attributes.WantedLevel):Connect(function()
		if WantedService.GetLevel(player) > 0 then
			ensureUnit(player)
		else
			cleanupUnit(player)
		end
	end)
	player.CharacterAdded:Connect(function()
		if WantedService.GetLevel(player) > 0 and not ArrestService.IsArrested(player) then
			task.defer(function()
				ensureUnit(player)
			end)
		end
	end)
end

function PoliceService.Start()
	assert(not started, "PoliceService.Start may only be called once")
	started = true

	local world = Workspace:WaitForChild(GameConfig.World.ContainerName)
	local spawns = world:WaitForChild("Spawns")
	local policeSpawns = spawns:WaitForChild("PoliceSpawns")
	for _, child in policeSpawns:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("SpawnType") == "PoliceResponse" then
			table.insert(responseMarkers, child)
		end
	end
	assert(#responseMarkers > 0, "PoliceService requires at least one PoliceResponse marker")

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
		if WantedService.GetLevel(player) > 0 then
			ensureUnit(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		cleanupUnit(player)
		lastDispatchAttempt[player] = nil
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		local now = os.clock()
		for player, unit in unitsByPlayer do
			if player.Parent ~= Players
				or WantedService.GetLevel(player) <= 0
				or ArrestService.IsArrested(player)
			then
				cleanupUnit(player)
			else
				updateUnit(unit, deltaTime, now)
			end
		end

		for _, player in Players:GetPlayers() do
			if WantedService.GetLevel(player) > 0
				and not unitsByPlayer[player]
				and not ArrestService.IsArrested(player)
				and now - (lastDispatchAttempt[player] or 0) >= PoliceConfig.Dispatch.RetryInterval
			then
				lastDispatchAttempt[player] = now
				ensureUnit(player)
			end
		end
	end)
end

return table.freeze(PoliceService)
