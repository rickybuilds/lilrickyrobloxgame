--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RobberyConfig = require(ReplicatedStorage.Shared.Config.RobberyConfig)
local EconomyService = require(script.Parent.EconomyService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local WantedService = require(script.Parent.WantedService)

local RobberyService = {}
local started = false

type StoreState = "Ready" | "Active" | "Cooldown"

type StoreRuntime = {
	Id: string,
	DisplayName: string,
	Cost: number,
	Reward: number,
	Duration: number,
	Cooldown: number,
	CrimeId: string,
	MaximumDistance: number,
	Register: BasePart,
	Prompt: ProximityPrompt,
	StatusLabel: TextLabel,
	State: StoreState,
	ActivePlayer: Player?,
	EndsAt: number,
	CooldownEndsAt: number,
	LastDisplayedSecond: number,
}

local storesById: { [string]: StoreRuntime } = {}
local activeStoreByPlayer: { [Player]: StoreRuntime } = {}
local lastTriggerAt: { [Player]: number } = {}

local function setTemporaryPlayerStatus(player: Player, message: string)
	PlayerStateService.SetRobberyStatus(player, message)
	task.delay(RobberyConfig.ResultMessageDuration, function()
		if player.Parent == Players and player:GetAttribute(GameConfig.Attributes.RobberyStatus) == message then
			PlayerStateService.SetRobberyStatus(player, GameConfig.PlayerDefaults.RobberyStatus)
		end
	end)
end

local function getEligibleRoot(player: Player): BasePart?
	if player.Parent ~= Players then
		return nil
	end

	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart ~= nil then
		return nil
	end
	if not root or not root:IsA("BasePart") then
		return nil
	end

	return root
end

local function isPlayerNearStore(player: Player, store: StoreRuntime): boolean
	local root = getEligibleRoot(player)
	return root ~= nil and (root.Position - store.Register.Position).Magnitude <= store.MaximumDistance
end

local function setWorldStatus(store: StoreRuntime, text: string, color: Color3)
	store.StatusLabel.Text = text
	store.StatusLabel.TextColor3 = color
end

local function setReady(store: StoreRuntime)
	store.State = "Ready"
	store.ActivePlayer = nil
	store.EndsAt = 0
	store.CooldownEndsAt = 0
	store.LastDisplayedSecond = -1
	store.Prompt.Enabled = store.Register:GetAttribute(RobberyConfig.EnabledAttribute) == true
	setWorldStatus(store, "READY", Color3.fromRGB(75, 255, 125))
end

local function cancelRobbery(store: StoreRuntime, message: string)
	if store.State ~= "Active" then
		return
	end

	local player = store.ActivePlayer
	if player then
		activeStoreByPlayer[player] = nil
		if player.Parent == Players then
			setTemporaryPlayerStatus(player, message)
		end
	end

	setReady(store)
end

local function completeRobbery(store: StoreRuntime)
	if store.State ~= "Active" then
		return
	end

	local player = store.ActivePlayer
	store.State = "Cooldown"
	store.ActivePlayer = nil
	store.EndsAt = 0
	store.CooldownEndsAt = os.clock() + store.Cooldown
	store.LastDisplayedSecond = -1
	store.Prompt.Enabled = false

	if player then
		activeStoreByPlayer[player] = nil
		local balance = EconomyService.AwardMoney(player, store.Reward, `robbery:{store.Id}`)
		if balance ~= nil then
			WantedService.ReportCrime(player, store.CrimeId)
			setTemporaryPlayerStatus(player, `Robbery complete! +${store.Reward}`)
		end
	end

	setWorldStatus(store, `COOLDOWN {math.ceil(store.Cooldown)}s`, Color3.fromRGB(255, 196, 70))
end

local function beginRobbery(player: Player, store: StoreRuntime)
	local now = os.clock()
	local previousTrigger = lastTriggerAt[player] or 0
	lastTriggerAt[player] = now
	if now - previousTrigger < RobberyConfig.TriggerRateLimit then
		return
	end

	-- Never trust prompt state or distance supplied by a client. An exploiter can
	-- fire prompt signals directly, so every important rule is checked here.
	if store.State ~= "Ready" or store.Register:GetAttribute(RobberyConfig.EnabledAttribute) ~= true then
		return
	end
	if activeStoreByPlayer[player] ~= nil or not isPlayerNearStore(player, store) then
		return
	end
	local balance = EconomyService.TrySpendMoney(player, store.Cost, `robbery-entry:{store.Id}`)
	if balance == nil then
		setTemporaryPlayerStatus(player, `You need ${store.Cost} to rob {store.DisplayName}`)
		return
	end

	store.State = "Active"
	store.ActivePlayer = player
	store.EndsAt = now + store.Duration
	store.LastDisplayedSecond = -1
	store.Prompt.Enabled = false
	activeStoreByPlayer[player] = store
	PlayerStateService.SetRobberyStatus(player, `Paid ${store.Cost} • Robbing {store.DisplayName}: {math.ceil(store.Duration)}s`)
	setWorldStatus(store, "ROBBERY IN PROGRESS", Color3.fromRGB(255, 90, 90))
end

local function createStatusLabel(register: BasePart): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RobberyStatusGui"
	billboard.Size = UDim2.fromOffset(140, 32)
	billboard.StudsOffset = Vector3.new(0, 1.3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 50
	billboard.Adornee = register
	billboard.Parent = register

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(22, 27, 35)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0.6
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	return label
end

local function registerStore(register: BasePart, storeId: string)
	local settings = RobberyConfig.Stores[storeId]
	if not settings then
		warn(`RobberyService ignored unknown store id: {storeId}`)
		return
	end
	if storesById[storeId] then
		warn(`RobberyService found duplicate store id: {storeId}`)
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RobberyPrompt"
	prompt.ActionText = settings.ActionText
	prompt.ObjectText = `{settings.DisplayName} • COST ${settings.Cost}`
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = settings.HoldDuration
	prompt.MaxActivationDistance = settings.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = register

	local store: StoreRuntime = {
		Id = storeId,
		DisplayName = settings.DisplayName,
		Cost = settings.Cost,
		Reward = settings.Reward,
		Duration = settings.Duration,
		Cooldown = settings.Cooldown,
		CrimeId = settings.CrimeId,
		MaximumDistance = settings.MaximumDistance,
		Register = register,
		Prompt = prompt,
		StatusLabel = createStatusLabel(register),
		State = "Ready",
		ActivePlayer = nil,
		EndsAt = 0,
		CooldownEndsAt = 0,
		LastDisplayedSecond = -1,
	}

	storesById[storeId] = store
	setReady(store)
	prompt.Triggered:Connect(function(player: Player)
		beginRobbery(player, store)
	end)
end

local function updateStores()
	local now = os.clock()
	for _, store in storesById do
		if store.State == "Active" then
			local player = store.ActivePlayer
			if not player or not isPlayerNearStore(player, store) then
				cancelRobbery(store, "Robbery cancelled: stay near the register")
			elseif now >= store.EndsAt then
				completeRobbery(store)
			else
				local remaining = math.max(1, math.ceil(store.EndsAt - now))
				if remaining ~= store.LastDisplayedSecond then
					store.LastDisplayedSecond = remaining
					PlayerStateService.SetRobberyStatus(player, `Paid ${store.Cost} • Robbing {store.DisplayName}: {remaining}s`)
				end
			end
		elseif store.State == "Cooldown" then
			if now >= store.CooldownEndsAt then
				setReady(store)
			else
				local remaining = math.max(1, math.ceil(store.CooldownEndsAt - now))
				if remaining ~= store.LastDisplayedSecond then
					store.LastDisplayedSecond = remaining
					setWorldStatus(store, `COOLDOWN {remaining}s`, Color3.fromRGB(255, 196, 70))
				end
			end
		end
	end
end

function RobberyService.Start()
	assert(not started, "RobberyService.Start may only be called once")
	started = true

	for _, descendant in workspace:GetDescendants() do
		local storeId = descendant:GetAttribute(RobberyConfig.StoreIdAttribute)
		if typeof(storeId) == "string" and descendant:IsA("BasePart") then
			registerStore(descendant, storeId)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		lastTriggerAt[player] = nil
		local store = activeStoreByPlayer[player]
		if store then
			cancelRobbery(store, "Robbery cancelled")
		end
	end)

	RunService.Heartbeat:Connect(updateStores)
end

return table.freeze(RobberyService)
