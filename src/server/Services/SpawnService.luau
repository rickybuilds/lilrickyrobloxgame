--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SpawnConfig = require(ReplicatedStorage.Shared.Config.SpawnConfig)
local PlayerStateService = require(script.Parent.PlayerStateService)

local SpawnService = {}
local started = false
local lastChoiceAt: { [Player]: number } = {}

local function isNear(player: Player, part: BasePart): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return humanoid ~= nil
		and humanoid.Health > 0
		and humanoid.SeatPart == nil
		and root ~= nil
		and root:IsA("BasePart")
		and (root.Position - part.Position).Magnitude <= SpawnConfig.InteractionDistance
end

local function chooseSpawn(
	player: Player,
	gate: BasePart,
	choiceId: string,
	destinations: { [string]: SpawnLocation }
)
	local now = os.clock()
	if now - (lastChoiceAt[player] or 0) < 1 then
		return
	end
	lastChoiceAt[player] = now
	if player:GetAttribute(GameConfig.Attributes.HasChosenSpawn) == true or not isNear(player, gate) then
		return
	end

	local destination = destinations[choiceId]
	if not destination then
		return
	end
	local character = player.Character
	if not character then
		return
	end

	player.RespawnLocation = destination
	player:SetAttribute(GameConfig.Attributes.HasChosenSpawn, true)
	player:SetAttribute(GameConfig.Attributes.SelectedSpawn, choiceId)
	local welcomeMessage = `Welcome to {choiceId}! Find a rental kiosk or explore.`
	PlayerStateService.SetRobberyStatus(player, welcomeMessage)
	task.delay(5, function()
		if player.Parent == Players and player:GetAttribute(GameConfig.Attributes.RobberyStatus) == welcomeMessage then
			PlayerStateService.SetRobberyStatus(player, GameConfig.PlayerDefaults.RobberyStatus)
		end
	end)
	task.defer(function()
		RunService.Heartbeat:Wait()
		if character.Parent then
			character:PivotTo(destination.CFrame + Vector3.new(0, 3, 0))
		end
	end)
end

function SpawnService.Start()
	assert(not started, "SpawnService.Start may only be called once")
	started = true
	local world = Workspace:WaitForChild(GameConfig.World.ContainerName)
	local spawns = world:WaitForChild("Spawns")
	local districtFolder = spawns:WaitForChild("DistrictSpawns")
	local destinations: { [string]: SpawnLocation } = {}
	for _, child in districtFolder:GetChildren() do
		local choiceId = child:GetAttribute("SpawnChoiceId")
		if child:IsA("SpawnLocation") and typeof(choiceId) == "string" then
			destinations[choiceId] = child
		end
	end

	local hub = world:WaitForChild("ArrivalHub")
	for _, descendant in hub:GetDescendants() do
		local choiceId = descendant:GetAttribute("SpawnChoiceId")
		if descendant:IsA("BasePart") and typeof(choiceId) == "string" and string.sub(descendant.Name, 1, 10) == "SpawnGate_" then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ChooseSpawnPrompt"
			prompt.ActionText = "Choose Spawn"
			prompt.ObjectText = choiceId
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.HoldDuration = 0.35
			prompt.MaxActivationDistance = SpawnConfig.InteractionDistance
			prompt.RequiresLineOfSight = false
			prompt.Parent = descendant
			prompt.Triggered:Connect(function(player)
				chooseSpawn(player, descendant, choiceId, destinations)
			end)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		lastChoiceAt[player] = nil
	end)
end

return table.freeze(SpawnService)
