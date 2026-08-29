--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SpawnConfig = require(ReplicatedStorage.Shared.Config.SpawnConfig)
local EconomyService = require(script.Parent.EconomyService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local VehicleService = require(script.Parent.VehicleService)

local RentalService = {}
local started = false
local activeRentalByPlayer: { [Player]: Model } = {}
local lastRentalAt: { [Player]: number } = {}

local function setTemporaryStatus(player: Player, message: string)
	PlayerStateService.SetRobberyStatus(player, message)
	task.delay(4, function()
		if player.Parent == Players and player:GetAttribute(GameConfig.Attributes.RobberyStatus) == message then
			PlayerStateService.SetRobberyStatus(player, GameConfig.PlayerDefaults.RobberyStatus)
		end
	end)
end

local function isPlayerEligible(player: Player, kiosk: BasePart): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return player.Parent == Players
		and player:GetAttribute(GameConfig.Attributes.Arrested) ~= true
		and (player:GetAttribute(GameConfig.Attributes.WantedLevel) or 0) == 0
		and humanoid ~= nil
		and humanoid.Health > 0
		and humanoid.SeatPart == nil
		and root ~= nil
		and root:IsA("BasePart")
		and (root.Position - kiosk.Position).Magnitude <= SpawnConfig.InteractionDistance
end

local function spawnIsClear(spawnCFrame: CFrame, spawns: Instance): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { spawns }
	local parts = Workspace:GetPartBoundsInBox(spawnCFrame * CFrame.new(0, 4, 0), Vector3.new(10, 5, 16), params)
	for _, part in parts do
		if part.CanCollide then
			return false
		end
	end
	return true
end

local function rentCar(
	player: Player,
	kiosk: BasePart,
	marker: BasePart,
	vehiclesFolder: Instance,
	spawns: Instance
)
	local now = os.clock()
	if now - (lastRentalAt[player] or 0) < 1 then
		return
	end
	lastRentalAt[player] = now
	if not isPlayerEligible(player, kiosk) then
		if (player:GetAttribute(GameConfig.Attributes.WantedLevel) or 0) > 0 then
			setTemporaryStatus(player, "Lose the police before renting a car")
		end
		return
	end

	local spawnCFrame = marker.CFrame * CFrame.new(0, 3.2, 0)
	if not spawnIsClear(marker.CFrame, spawns) then
		setTemporaryStatus(player, "Rental space blocked — move the car and try again")
		return
	end
	local balance = EconomyService.TrySpendMoney(player, SpawnConfig.RentalCost, "vehicle-rental")
	if balance == nil then
		setTemporaryStatus(player, `You need ${SpawnConfig.RentalCost} to rent a Gleep Glorp`)
		return
	end

	local oldRental = activeRentalByPlayer[player]
	if oldRental and oldRental.Parent then
		VehicleService.DestroyPlayerVehicle(oldRental)
	end
	local rental = VehicleService.CreateRentalVehicle(spawnCFrame, vehiclesFolder, player)
	activeRentalByPlayer[player] = rental
	setTemporaryStatus(player, `Gleep Glorp rented! ${balance} remaining`)
end

function RentalService.Start()
	assert(not started, "RentalService.Start may only be called once")
	started = true
	local world = Workspace:WaitForChild(GameConfig.World.ContainerName)
	local spawns = world:WaitForChild("Spawns")
	local vehiclesFolder = world:WaitForChild("Vehicles")
	local rentalDepots = world:WaitForChild("RentalDepots")
	local markers: { [string]: BasePart } = {}
	for _, child in spawns:GetChildren() do
		local markerId = child:GetAttribute("RentalSpawnId")
		if child:IsA("BasePart") and typeof(markerId) == "string" then
			markers[markerId] = child
		end
	end

	for _, descendant in rentalDepots:GetDescendants() do
		local kioskId = descendant:GetAttribute("RentalKioskId")
		if descendant:IsA("BasePart") and typeof(kioskId) == "string" and string.sub(descendant.Name, 1, 11) == "RentalKiosk" then
			local marker = markers[kioskId]
			assert(marker, `Missing rental spawn marker for {kioskId}`)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "RentalPrompt"
			prompt.ActionText = `Rent Car ${SpawnConfig.RentalCost}`
			prompt.ObjectText = "Gleep Glorp Rentals"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.HoldDuration = 0.5
			prompt.MaxActivationDistance = SpawnConfig.InteractionDistance
			prompt.RequiresLineOfSight = false
			prompt.Parent = descendant
			prompt.Triggered:Connect(function(player)
				rentCar(player, descendant, marker, vehiclesFolder, spawns)
			end)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		local rental = activeRentalByPlayer[player]
		if rental and rental.Parent then
			VehicleService.DestroyPlayerVehicle(rental)
		end
		activeRentalByPlayer[player] = nil
		lastRentalAt[player] = nil
	end)
end

return table.freeze(RentalService)
