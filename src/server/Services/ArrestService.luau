--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PoliceConfig = require(ReplicatedStorage.Shared.Config.PoliceConfig)
local EconomyService = require(script.Parent.EconomyService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local VehicleService = require(script.Parent.VehicleService)
local WantedService = require(script.Parent.WantedService)

local ArrestService = {}
local started = false
local activeArrests: { [Player]: BasePart } = {}
local jailCells: { BasePart } = {}
local reservedCells: { [BasePart]: Player } = {}
local releaseSpawn: BasePart

local function getCharacterParts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return character, humanoid, nil
	end
	return character, humanoid, root
end

local function placeInJail(player: Player): boolean
	local character, humanoid, root = getCharacterParts(player)
	local cell = activeArrests[player]
	if not character or not humanoid or not root or not cell then
		return false
	end

	humanoid.Sit = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	character:PivotTo(cell.CFrame + Vector3.new(0, 3, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	return true
end

local function releasePlayer(player: Player)
	local cell = activeArrests[player]
	if cell then
		reservedCells[cell] = nil
	end
	activeArrests[player] = nil
	player:SetAttribute(GameConfig.Attributes.Arrested, false)

	local character, humanoid, root = getCharacterParts(player)
	if character and humanoid and root then
		root.Anchored = false
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
		character:PivotTo(releaseSpawn.CFrame + Vector3.new(0, 3, 0))
	end

	PlayerStateService.SetRobberyStatus(player, "Released from jail")
	task.delay(PoliceConfig.Arrest.JailDuration / 2, function()
		if player.Parent == Players
			and player:GetAttribute(GameConfig.Attributes.RobberyStatus) == "Released from jail"
		then
			PlayerStateService.SetRobberyStatus(player, GameConfig.PlayerDefaults.RobberyStatus)
		end
	end)
end

function ArrestService.Start()
	assert(not started, "ArrestService.Start may only be called once")
	started = true

	local world = workspace:WaitForChild(GameConfig.World.ContainerName)
	local landmarks = world:WaitForChild("Landmarks")
	local jail = landmarks:WaitForChild("Jail")
	local releaseSpawnInstance = jail:WaitForChild("ReleaseSpawn")
	assert(releaseSpawnInstance:IsA("BasePart"), "ReleaseSpawn must be a BasePart")
	releaseSpawn = releaseSpawnInstance
	for _, child in jail:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("SpawnType") == "JailCell" then
			table.insert(jailCells, child)
		end
	end
	table.sort(jailCells, function(left, right)
		return left.Name < right.Name
	end)
	assert(#jailCells == 4, "ArrestService requires four JailCell spawn parts")

	local function watchPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			if activeArrests[player] then
				task.spawn(function()
					-- CharacterAdded can fire before the HumanoidRootPart is parented.
					-- Retry briefly so resetting cannot be used to escape jail.
					for _ = 1, 50 do
						if not activeArrests[player] or player.Parent ~= Players then
							return
						end
						if placeInJail(player) then
							return
						end
						task.wait(0.1)
					end
				end)
			end
		end)
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local cell = activeArrests[player]
		if cell then
			reservedCells[cell] = nil
		end
		activeArrests[player] = nil
	end)
end

function ArrestService.IsArrested(player: Player): boolean
	return activeArrests[player] ~= nil
end

local function reserveCell(player: Player): BasePart?
	for _, cell in jailCells do
		if reservedCells[cell] == nil then
			reservedCells[cell] = player
			return cell
		end
	end
	return nil
end

function ArrestService.Arrest(player: Player): boolean
	assert(started, "ArrestService must be started before arresting players")
	if player.Parent ~= Players or activeArrests[player] or WantedService.GetLevel(player) <= 0 then
		return false
	end

	local cell = reserveCell(player)
	if not cell then
		return false
	end
	activeArrests[player] = cell
	player:SetAttribute(GameConfig.Attributes.Arrested, true)
	PlayerStateService.SetPoliceState(player, "Clear", 0)
	VehicleService.ForceExit(player)

	local confiscated = EconomyService.ConfiscateRobberyProceeds(
		player,
		PoliceConfig.Arrest.ConfiscationFraction
	)
	EconomyService.SecureRobberyProceeds(player)
	WantedService.ClearWanted(player)
	placeInJail(player)

	task.spawn(function()
		for remaining = PoliceConfig.Arrest.JailDuration, 1, -1 do
			if player.Parent ~= Players or not activeArrests[player] then
				return
			end
			local moneyText = if confiscated > 0 then ` • ${confiscated} confiscated` else ""
			PlayerStateService.SetRobberyStatus(player, `Arrested{moneyText} • Jail {remaining}s`)
			task.wait(1)
		end

		if player.Parent == Players and activeArrests[player] then
			releasePlayer(player)
		end
	end)

	return true
end

return table.freeze(ArrestService)
