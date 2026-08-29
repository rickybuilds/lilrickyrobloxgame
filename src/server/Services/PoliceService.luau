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
local EconomyService = require(script.Parent.EconomyService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local VehicleService = require(script.Parent.VehicleService)
local WantedService = require(script.Parent.WantedService)

local PoliceService = {}
local started = false

type UnitState = "VehiclePursuit" | "FootPursuit" | "ReturningToVehicle"
type AwarenessState = "Pursuit" | "Searching" | "Returning"

type PoliceUnit = {
	Target: Player,
	State: UnitState,
	Awareness: AwarenessState,
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
	SightRaycastParams: RaycastParams,
	TargetVisible: boolean,
	HasEstablishedContact: boolean,
	DispatchStartedAt: number,
	LastSightCheck: number,
	LastSeenPosition: Vector3,
	LastSeenAt: number,
	HiddenSince: number?,
	SearchDestination: Vector3,
	NextSearchMoveAt: number,
	SearchStep: number,
	LastHudSecond: number,
	ReturnStartedAt: number?,
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

local SEARCH_OFFSETS = {
	Vector3.new(1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, -1),
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

local function getSeatedVehicle(humanoid: Humanoid): Model?
	local seat = humanoid.SeatPart
	if not seat then
		return nil
	end
	return seat:FindFirstAncestorWhichIsA("Model")
end

local function canSeeTarget(
	unit: PoliceUnit,
	targetCharacter: Model,
	targetHumanoid: Humanoid,
	targetRoot: BasePart
): boolean
	local observerRoot = unit.OfficerRoot or unit.VehicleRoot
	local origin = observerRoot.Position + Vector3.new(0, 2, 0)
	local targetPosition = targetRoot.Position + Vector3.new(0, 1.5, 0)
	local offset = targetPosition - origin
	if offset.Magnitude > PoliceConfig.Search.MaximumSightDistance then
		return false
	end

	local exclusions: { Instance } = { unit.Vehicle }
	if unit.Officer then
		table.insert(exclusions, unit.Officer)
	end
	unit.SightRaycastParams.FilterDescendantsInstances = exclusions
	local result = Workspace:Raycast(origin, offset, unit.SightRaycastParams)
	if not result then
		return true
	end
	if result.Instance:IsDescendantOf(targetCharacter) then
		return true
	end
	local targetVehicle = getSeatedVehicle(targetHumanoid)
	return targetVehicle ~= nil and result.Instance:IsDescendantOf(targetVehicle)
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
	if unit.Awareness == "Returning" then
		for _, descendant in unit.Vehicle:GetDescendants() do
			if descendant:IsA("BasePart") and descendant:GetAttribute("PoliceSirenLight") ~= nil then
				descendant.Transparency = 0.65
			end
		end
		return
	end

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

local function resumePursuit(unit: PoliceUnit, targetPosition: Vector3, now: number, hasContact: boolean)
	unit.Awareness = "Pursuit"
	unit.TargetVisible = hasContact
	unit.HasEstablishedContact = hasContact
	unit.DispatchStartedAt = now
	unit.LastSeenPosition = targetPosition
	unit.LastSeenAt = now
	unit.HiddenSince = nil
	unit.SearchDestination = targetPosition
	unit.LastHudSecond = -1
	unit.ReturnStartedAt = nil
	PlayerStateService.SetPoliceState(unit.Target, "Pursuit", 0)
end

local function beginSearch(unit: PoliceUnit, now: number)
	if unit.Awareness == "Searching" then
		return
	end
	unit.Awareness = "Searching"
	unit.HiddenSince = now
	unit.SearchDestination = unit.LastSeenPosition
	unit.NextSearchMoveAt = 0
	unit.SearchStep = 0
	unit.LastHudSecond = -1
	unit.ArrestStartedAt = nil
	PlayerStateService.SetPoliceState(unit.Target, "Searching", 0)
end

local function beginReturn(unit: PoliceUnit, now: number)
	if unit.Awareness == "Returning" then
		return
	end
	unit.Awareness = "Returning"
	unit.HiddenSince = nil
	unit.ReturnStartedAt = now
	unit.ArrestStartedAt = nil
	PlayerStateService.SetPoliceState(unit.Target, "Clear", 0)
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
	local sightRaycastParams = RaycastParams.new()
	sightRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	sightRaycastParams.FilterDescendantsInstances = { vehicle }
	sightRaycastParams.IgnoreWater = true
	sightRaycastParams.RespectCanCollide = false

	local now = os.clock()
	local unit: PoliceUnit = {
		Target = player,
		State = "VehiclePursuit",
		Awareness = "Pursuit",
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
		SightRaycastParams = sightRaycastParams,
		TargetVisible = false,
		HasEstablishedContact = false,
		DispatchStartedAt = now,
		LastSightCheck = 0,
		LastSeenPosition = targetRoot.Position,
		LastSeenAt = now,
		HiddenSince = nil,
		SearchDestination = targetRoot.Position,
		NextSearchMoveAt = 0,
		SearchStep = 0,
		LastHudSecond = -1,
		ReturnStartedAt = nil,
	}
	unitsByPlayer[player] = unit
	reservedMarkers[marker] = player
	PlayerStateService.SetRobberyStatus(player, "Police dispatched from the station!")
	PlayerStateService.SetPoliceState(player, "Pursuit", 0)
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

local function driveVehicleToPosition(
	unit: PoliceUnit,
	destination: Vector3,
	speedLimit: number,
	stopDistance: number,
	deltaTime: number,
	now: number
): (number, number)
	local toDestination = horizontal(destination - unit.VehicleRoot.Position)
	local distance = toDestination.Magnitude
	local speed = horizontal(unit.VehicleRoot.AssemblyLinearVelocity).Magnitude
	if distance < 0.001 then
		VehicleService.StepNpcVehicle(unit.Vehicle, PARKED_CONTROLS, deltaTime)
		return distance, speed
	end

	local direction = toDestination.Unit
	local localDirection = unit.VehicleRoot.CFrame:VectorToObjectSpace(direction)
	local steering = math.clamp(localDirection.X * 2.2, -1, 1)

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
	elseif distance <= stopDistance or speed > speedLimit then
		throttle = 0
		brake = 1
	end

	local obstacle = Workspace:Raycast(
		unit.VehicleRoot.Position + Vector3.new(0, 1, 0),
		unit.VehicleRoot.CFrame.LookVector * PoliceConfig.Vehicle.ObstacleCheckDistance,
		unit.RaycastParams
	)
	if obstacle and now >= unit.ReverseUntil and distance > stopDistance then
		steering = unit.AvoidanceSign
		throttle = 0.35
		brake = 0
	end

	local controls: VehicleDynamics.ControlState = {
		Throttle = throttle,
		Steering = steering,
		Brake = brake,
		Handbrake = distance <= stopDistance,
		Parked = false,
	}
	VehicleService.StepNpcVehicle(unit.Vehicle, controls, deltaTime)
	return distance, speed
end

local function updateVehiclePursuit(
	unit: PoliceUnit,
	targetCharacter: Model,
	targetHumanoid: Humanoid,
	targetRoot: BasePart,
	deltaTime: number,
	now: number
)
	unit.RaycastParams.FilterDescendantsInstances = { unit.Vehicle, targetCharacter }
	local targetSpeed = horizontal(targetRoot.AssemblyLinearVelocity).Magnitude
	local targetSeated = targetHumanoid.SeatPart ~= nil
	local distanceToTarget = horizontal(targetRoot.Position - unit.VehicleRoot.Position).Magnitude
	local preparingToDismount = (not targetSeated and distanceToTarget <= PoliceConfig.Vehicle.DismountDistance)
		or (targetSeated and targetSpeed <= PoliceConfig.Arrest.MaximumSuspectSpeed and distanceToTarget <= 20)
	local wantedLevel = WantedService.GetLevel(unit.Target)
	local speedLimit = PoliceConfig.Vehicle.ResponseSpeeds[wantedLevel]
		or PoliceConfig.Vehicle.ResponseSpeeds[GameConfig.Wanted.MaximumLevel]
	local stopDistance = if preparingToDismount then math.min(distanceToTarget, 18) else 0
	local _, speed = driveVehicleToPosition(
		unit,
		targetRoot.Position,
		speedLimit,
		stopDistance,
		deltaTime,
		now
	)

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

local function returnOfficerToVehicle(unit: PoliceUnit, deltaTime: number, now: number)
	VehicleService.StepNpcVehicle(unit.Vehicle, PARKED_CONTROLS, deltaTime)
	local officerRoot = unit.OfficerRoot
	if not officerRoot then
		reboardOfficer(unit)
		return
	end
	unit.State = "ReturningToVehicle"
	moveOfficer(unit, unit.VehicleRoot.Position, now)
	if horizontal(unit.VehicleRoot.Position - officerRoot.Position).Magnitude
		<= PoliceConfig.Officer.ReboardDistance
	then
		reboardOfficer(unit)
	end
end

local function updateSearchMovement(unit: PoliceUnit, deltaTime: number, now: number)
	if unit.State == "ReturningToVehicle" then
		returnOfficerToVehicle(unit, deltaTime, now)
		return
	end

	if unit.State == "VehiclePursuit" then
		unit.RaycastParams.FilterDescendantsInstances = { unit.Vehicle }
		local distance, speed = driveVehicleToPosition(
			unit,
			unit.SearchDestination,
			PoliceConfig.Search.VehicleSpeed,
			PoliceConfig.Search.ArrivalDistance,
			deltaTime,
			now
		)
		if distance <= PoliceConfig.Search.ArrivalDistance and speed <= 9 then
			dismountOfficer(unit)
		end
		return
	end

	VehicleService.StepNpcVehicle(unit.Vehicle, PARKED_CONTROLS, deltaTime)
	local officerRoot = unit.OfficerRoot
	if not officerRoot then
		reboardOfficer(unit)
		return
	end

	local reachedDestination = horizontal(unit.SearchDestination - officerRoot.Position).Magnitude <= 5
	if unit.Awareness == "Searching" and reachedDestination and now >= unit.NextSearchMoveAt then
		unit.SearchStep = (unit.SearchStep % #SEARCH_OFFSETS) + 1
		unit.SearchDestination = unit.LastSeenPosition
			+ SEARCH_OFFSETS[unit.SearchStep] * PoliceConfig.Search.SweepRadius
		unit.NextSearchMoveAt = now + PoliceConfig.Search.SweepInterval
		unit.PathWaypoints = {}
		unit.WaypointIndex = 1
	end
	moveOfficer(unit, unit.SearchDestination, now)
end

local function updateReturnMovement(unit: PoliceUnit, deltaTime: number, now: number)
	local returnStartedAt = unit.ReturnStartedAt or now
	if now - returnStartedAt >= PoliceConfig.Return.Timeout then
		cleanupUnit(unit.Target)
		return
	end

	if unit.Officer then
		returnOfficerToVehicle(unit, deltaTime, now)
		return
	end

	unit.RaycastParams.FilterDescendantsInstances = { unit.Vehicle }
	local distance, speed = driveVehicleToPosition(
		unit,
		unit.SpawnMarker.Position,
		PoliceConfig.Return.VehicleSpeed,
		PoliceConfig.Return.ArrivalDistance,
		deltaTime,
		now
	)
	if distance <= PoliceConfig.Return.ArrivalDistance and speed <= 7 then
		cleanupUnit(unit.Target)
	end
end

local function updateSight(unit: PoliceUnit, targetCharacter: Model, targetHumanoid: Humanoid, targetRoot: BasePart, now: number)
	if now - unit.LastSightCheck < PoliceConfig.Search.SightCheckInterval then
		return
	end
	unit.LastSightCheck = now
	local visible = canSeeTarget(unit, targetCharacter, targetHumanoid, targetRoot)
	unit.TargetVisible = visible
	if visible then
		unit.HasEstablishedContact = true
		local wasSearching = unit.Awareness == "Searching"
		unit.LastSeenPosition = targetRoot.Position
		unit.LastSeenAt = now
		unit.SearchDestination = targetRoot.Position
		if wasSearching then
			resumePursuit(unit, targetRoot.Position, now, true)
			PlayerStateService.SetRobberyStatus(unit.Target, "Police spotted you — escape reset!")
		end
	elseif unit.Awareness == "Pursuit" then
		if not unit.HasEstablishedContact then
			-- Dispatch supplies approximate live updates until the responding unit
			-- reaches the scene. This prevents a distant station spawn from starting
			-- the escape timer before police have had a fair chance to arrive.
			unit.LastSeenPosition = targetRoot.Position
			unit.SearchDestination = targetRoot.Position
			unit.LastSeenAt = now
			if now - unit.DispatchStartedAt >= PoliceConfig.Dispatch.MaximumTrackingTime then
				beginSearch(unit, now)
			end
		elseif now - unit.LastSeenAt >= PoliceConfig.Search.LostSightGrace then
			beginSearch(unit, now)
		end
	end
end

local function updateEscapeCountdown(unit: PoliceUnit, now: number)
	if unit.Awareness ~= "Searching" then
		return
	end
	local hiddenSince = unit.HiddenSince
	if not hiddenSince then
		unit.HiddenSince = now
		hiddenSince = now
	end

	local wantedLevel = WantedService.GetLevel(unit.Target)
	if wantedLevel <= 0 then
		beginReturn(unit, now)
		return
	end
	local duration = PoliceConfig.Search.EscapeSecondsPerLevel[wantedLevel]
		or PoliceConfig.Search.EscapeSecondsPerLevel[GameConfig.Wanted.MaximumLevel]
	local remaining = math.max(0, math.ceil(duration - (now - hiddenSince)))
	if remaining ~= unit.LastHudSecond then
		unit.LastHudSecond = remaining
		PlayerStateService.SetPoliceState(unit.Target, "Searching", remaining)
	end
	if remaining > 0 then
		return
	end

	local newLevel = WantedService.ReduceWanted(unit.Target, 1)
	if not newLevel then
		return
	end
	if newLevel <= 0 then
		EconomyService.SecureRobberyProceeds(unit.Target)
		local escapeMessage = "You escaped! Wanted cleared — keep the money."
		PlayerStateService.SetRobberyStatus(unit.Target, escapeMessage)
		beginReturn(unit, now)
		task.delay(4, function()
			if unit.Target.Parent == Players
				and unit.Target:GetAttribute(GameConfig.Attributes.RobberyStatus) == escapeMessage
			then
				PlayerStateService.SetRobberyStatus(unit.Target, GameConfig.PlayerDefaults.RobberyStatus)
			end
		end)
	else
		unit.HiddenSince = now
		unit.LastHudSecond = -1
		PlayerStateService.SetRobberyStatus(unit.Target, `Escaped one star — {newLevel} remaining.`)
	end
end

local function updateUnit(unit: PoliceUnit, deltaTime: number, now: number)
	if not unit.Vehicle.Parent then
		cleanupUnit(unit.Target)
		return
	end
	setSirenLights(unit, now)
	if unit.Awareness == "Returning" then
		if WantedService.GetLevel(unit.Target) > 0 then
			local _, _, targetRoot = getLivingTarget(unit.Target)
			local targetPosition = if targetRoot then targetRoot.Position else unit.LastSeenPosition
			resumePursuit(unit, targetPosition, now, false)
		else
			updateReturnMovement(unit, deltaTime, now)
			return
		end
	end

	local targetCharacter, targetHumanoid, targetRoot = getLivingTarget(unit.Target)
	if not targetCharacter or not targetHumanoid or not targetRoot then
		unit.TargetVisible = false
		if unit.Awareness == "Pursuit" then
			local contactExpired = unit.HasEstablishedContact
				and now - unit.LastSeenAt >= PoliceConfig.Search.LostSightGrace
			local dispatchExpired = not unit.HasEstablishedContact
				and now - unit.DispatchStartedAt >= PoliceConfig.Dispatch.MaximumTrackingTime
			if contactExpired or dispatchExpired then
				beginSearch(unit, now)
			end
		end
		updateEscapeCountdown(unit, now)
		if unit.Awareness == "Returning" then
			updateReturnMovement(unit, deltaTime, now)
		else
			updateSearchMovement(unit, deltaTime, now)
		end
		return
	end
	updateSight(unit, targetCharacter, targetHumanoid, targetRoot, now)
	updateEscapeCountdown(unit, now)
	if unit.Awareness == "Returning" then
		updateReturnMovement(unit, deltaTime, now)
		return
	end

	if unit.Awareness == "Pursuit" and unit.TargetVisible and unit.State == "VehiclePursuit" then
		updateVehiclePursuit(unit, targetCharacter, targetHumanoid, targetRoot, deltaTime, now)
	elseif unit.Awareness == "Pursuit" and unit.TargetVisible then
		updateFootPursuit(unit, targetHumanoid, targetRoot, deltaTime, now)
	else
		updateSearchMovement(unit, deltaTime, now)
	end
end

local function handleCrimeReported(player: Player, _crimeId: string, _wantedLevel: number)
	local unit = unitsByPlayer[player]
	if not unit then
		ensureUnit(player)
		return
	end

	local _, _, targetRoot = getLivingTarget(player)
	local targetPosition = if targetRoot then targetRoot.Position else unit.LastSeenPosition
	if unit.Awareness == "Returning" then
		-- A completed escape ends the old response. A later crime receives a new
		-- station dispatch instead of reviving a distant or stuck returning unit.
		cleanupUnit(player)
		ensureUnit(player)
	elseif unit.Awareness == "Searching" or not unit.TargetVisible then
		-- A new crime is a fresh dispatch location. The current unit can respond,
		-- but it must stop searching the obsolete last-seen position.
		resumePursuit(unit, targetPosition, os.clock(), false)
		PlayerStateService.SetRobberyStatus(player, "New crime reported — police redirected!")
	end
end

local function watchPlayer(player: Player)
	player:GetAttributeChangedSignal(GameConfig.Attributes.WantedLevel):Connect(function()
		if WantedService.GetLevel(player) > 0 then
			ensureUnit(player)
		else
			local unit = unitsByPlayer[player]
			if unit then
				if ArrestService.IsArrested(player) then
					cleanupUnit(player)
				else
					beginReturn(unit, os.clock())
				end
			end
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
	WantedService.ConnectCrimeReported(handleCrimeReported)

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
