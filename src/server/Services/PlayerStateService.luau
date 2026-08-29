--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PlayerStateService = {}
local started = false

local function initializePlayer(player: Player)
	-- These values are session-only in Milestone 1. A later PlayerDataService will
	-- load/save persistent data without changing the HUD's public attributes.
	player:SetAttribute(GameConfig.Attributes.Money, GameConfig.PlayerDefaults.Money)
	player:SetAttribute(GameConfig.Attributes.WantedLevel, GameConfig.PlayerDefaults.WantedLevel)
	player:SetAttribute(GameConfig.Attributes.RobberyStatus, GameConfig.PlayerDefaults.RobberyStatus)
	player:SetAttribute(GameConfig.Attributes.Arrested, GameConfig.PlayerDefaults.Arrested)

	-- Point every player at our named spawn. This prevents a leftover SpawnLocation
	-- from the Studio Baseplate template from being selected at random.
	local gameWorld = workspace:FindFirstChild(GameConfig.World.ContainerName)
	local spawns = if gameWorld then gameWorld:FindFirstChild("Spawns") else nil
	local playerSpawn = if spawns then spawns:FindFirstChild("PlayerSpawn") else nil
	if playerSpawn and playerSpawn:IsA("SpawnLocation") then
		player.RespawnLocation = playerSpawn
	end
end

function PlayerStateService.Start()
	assert(not started, "PlayerStateService.Start may only be called once")
	started = true

	Players.PlayerAdded:Connect(initializePlayer)

	for _, player in Players:GetPlayers() do
		initializePlayer(player)
	end
end

function PlayerStateService.GetMoney(player: Player): number
	local value = player:GetAttribute(GameConfig.Attributes.Money)
	return if typeof(value) == "number" then value else 0
end

function PlayerStateService.AddMoney(player: Player, amount: number): number
	assert(amount >= 0 and amount % 1 == 0, "Money awards must be non-negative whole numbers")

	local newBalance = PlayerStateService.GetMoney(player) + amount
	player:SetAttribute(GameConfig.Attributes.Money, newBalance)
	return newBalance
end

function PlayerStateService.RemoveMoney(player: Player, amount: number): number
	assert(amount >= 0 and amount % 1 == 0, "Money deductions must be non-negative whole numbers")

	local newBalance = math.max(0, PlayerStateService.GetMoney(player) - amount)
	player:SetAttribute(GameConfig.Attributes.Money, newBalance)
	return newBalance
end

function PlayerStateService.SetWantedLevel(player: Player, requestedLevel: number): number
	local level = math.clamp(
		math.floor(requestedLevel),
		GameConfig.Wanted.MinimumLevel,
		GameConfig.Wanted.MaximumLevel
	)

	player:SetAttribute(GameConfig.Attributes.WantedLevel, level)
	return level
end

function PlayerStateService.SetRobberyStatus(player: Player, status: string)
	assert(#status <= 80, "Robbery status is too long")
	player:SetAttribute(GameConfig.Attributes.RobberyStatus, status)
end

return table.freeze(PlayerStateService)
