--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local HudController = {}

local function roundCorners(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function makeLabel(name: string, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

function HudController.Start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	local statsPanel = Instance.new("Frame")
	statsPanel.Name = "StatsPanel"
	statsPanel.Size = UDim2.fromOffset(270, 98)
	statsPanel.Position = UDim2.fromOffset(18, 18)
	statsPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
	statsPanel.BackgroundTransparency = 0.12
	statsPanel.Parent = screenGui
	roundCorners(statsPanel, 12)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = statsPanel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.Parent = statsPanel

	local moneyLabel = makeLabel("Money", statsPanel)
	moneyLabel.LayoutOrder = 1
	moneyLabel.Size = UDim2.new(1, 0, 0, 34)
	moneyLabel.TextColor3 = Color3.fromRGB(104, 239, 125)

	local wantedLabel = makeLabel("Wanted", statsPanel)
	wantedLabel.LayoutOrder = 2
	wantedLabel.Size = UDim2.new(1, 0, 0, 34)
	wantedLabel.TextColor3 = Color3.fromRGB(255, 210, 69)

	local statusPanel = Instance.new("Frame")
	statusPanel.Name = "ActivityPanel"
	statusPanel.AnchorPoint = Vector2.new(0.5, 1)
	statusPanel.Size = UDim2.fromOffset(420, 54)
	statusPanel.Position = UDim2.new(0.5, 0, 1, -24)
	statusPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
	statusPanel.BackgroundTransparency = 0.1
	statusPanel.Parent = screenGui
	roundCorners(statusPanel, 12)

	local statusLabel = makeLabel("RobberyStatus", statusPanel)
	statusLabel.Size = UDim2.new(1, -24, 1, -12)
	statusLabel.Position = UDim2.fromOffset(12, 6)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center

	local function updateMoney()
		local money = player:GetAttribute(GameConfig.Attributes.Money)
		moneyLabel.Text = `${if typeof(money) == "number" then money else 0}`
	end

	local function updateWanted()
		local rawLevel = player:GetAttribute(GameConfig.Attributes.WantedLevel)
		local level = if typeof(rawLevel) == "number" then math.clamp(math.floor(rawLevel), 0, 5) else 0
		wantedLabel.Text = `WANTED  {string.rep("★", level)}{string.rep("☆", 5 - level)}`
	end

	local function updateStatus()
		local status = player:GetAttribute(GameConfig.Attributes.RobberyStatus)
		statusLabel.Text = if typeof(status) == "string" then status else "Explore the city"
	end

	player:GetAttributeChangedSignal(GameConfig.Attributes.Money):Connect(updateMoney)
	player:GetAttributeChangedSignal(GameConfig.Attributes.WantedLevel):Connect(updateWanted)
	player:GetAttributeChangedSignal(GameConfig.Attributes.RobberyStatus):Connect(updateStatus)

	updateMoney()
	updateWanted()
	updateStatus()
end

return table.freeze(HudController)
