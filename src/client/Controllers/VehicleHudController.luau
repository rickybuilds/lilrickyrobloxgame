--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleConfig = require(ReplicatedStorage.Shared.Config.VehicleConfig)

local VehicleHudController = {}
local started = false
local screenGui: ScreenGui
local speedLabel: TextLabel
local gearLabel: TextLabel
local handbrakeLabel: TextLabel
local healthFill: Frame
local healthLabel: TextLabel
local driverPanel: Frame
local passengerPanel: Frame

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
	label.Parent = parent
	return label
end

function VehicleHudController.Start()
	assert(not started, "VehicleHudController.Start may only be called once")
	started = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VehicleHud"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 11
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	driverPanel = Instance.new("Frame")
	driverPanel.Name = "SpeedometerPanel"
	driverPanel.AnchorPoint = Vector2.new(1, 1)
	driverPanel.Size = UDim2.fromOffset(230, 160)
	driverPanel.Position = UDim2.new(1, -22, 1, -22)
	driverPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
	driverPanel.BackgroundTransparency = 0.08
	driverPanel.Parent = screenGui
	roundCorners(driverPanel, 14)

	speedLabel = makeLabel("Speed", driverPanel)
	speedLabel.Size = UDim2.new(1, -24, 0, 68)
	speedLabel.Position = UDim2.fromOffset(12, 8)
	speedLabel.Text = "0 MPH"

	gearLabel = makeLabel("Gear", driverPanel)
	gearLabel.Size = UDim2.fromOffset(48, 34)
	gearLabel.Position = UDim2.fromOffset(14, 72)
	gearLabel.Text = "P"
	gearLabel.TextColor3 = Color3.fromRGB(90, 210, 255)

	handbrakeLabel = makeLabel("Handbrake", driverPanel)
	handbrakeLabel.Size = UDim2.new(1, -78, 0, 30)
	handbrakeLabel.Position = UDim2.fromOffset(66, 74)
	handbrakeLabel.Text = "SPACE: HANDBRAKE"
	handbrakeLabel.TextColor3 = Color3.fromRGB(190, 195, 205)

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, -24, 0, 30)
	healthBar.Position = UDim2.new(0, 12, 1, -42)
	healthBar.BackgroundColor3 = Color3.fromRGB(62, 68, 78)
	healthBar.Parent = driverPanel
	roundCorners(healthBar, 8)

	healthFill = Instance.new("Frame")
	healthFill.Name = "Fill"
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(81, 220, 112)
	healthFill.Parent = healthBar
	roundCorners(healthFill, 8)

	healthLabel = makeLabel("HealthText", healthBar)
	healthLabel.Size = UDim2.fromScale(1, 1)
	healthLabel.Text = "CAR 100 / 100"

	passengerPanel = Instance.new("Frame")
	passengerPanel.Name = "PassengerExitPanel"
	passengerPanel.AnchorPoint = Vector2.new(1, 1)
	passengerPanel.Size = UDim2.fromOffset(230, 58)
	passengerPanel.Position = UDim2.new(1, -22, 1, -22)
	passengerPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
	passengerPanel.BackgroundTransparency = 0.08
	passengerPanel.Visible = false
	passengerPanel.Parent = screenGui
	roundCorners(passengerPanel, 14)

	local passengerExitLabel = makeLabel("ExitHint", passengerPanel)
	passengerExitLabel.Size = UDim2.new(1, -20, 1, -12)
	passengerExitLabel.Position = UDim2.fromOffset(10, 6)
	passengerExitLabel.Text = "E  •  EXIT VEHICLE"
	passengerExitLabel.TextColor3 = Color3.fromRGB(90, 210, 255)
end

function VehicleHudController.SetVisible(visible: boolean)
	assert(started, "VehicleHudController must be started before use")
	driverPanel.Visible = visible
	if visible then
		passengerPanel.Visible = false
	end
	screenGui.Enabled = driverPanel.Visible or passengerPanel.Visible
end

function VehicleHudController.SetPassengerVisible(visible: boolean)
	assert(started, "VehicleHudController must be started before use")
	passengerPanel.Visible = visible
	if visible then
		driverPanel.Visible = false
	end
	screenGui.Enabled = driverPanel.Visible or passengerPanel.Visible
end

function VehicleHudController.Update(
	speedStudsPerSecond: number,
	forwardSpeed: number,
	health: number,
	maximumHealth: number,
	handbrake: boolean,
	parked: boolean
)
	assert(started, "VehicleHudController must be started before use")
	local milesPerHour = math.floor(speedStudsPerSecond * VehicleConfig.Display.StudsPerSecondToMPH + 0.5)
	speedLabel.Text = `{milesPerHour} MPH`
	gearLabel.Text = if parked then "P" elseif forwardSpeed < -0.5 then "R" else "D"
	handbrakeLabel.Text = if parked
		then "PARKED • P RELEASE • E EXIT"
		elseif handbrake then "HANDBRAKE • E EXIT"
		else "SPACE BRAKE • E EXIT"
	handbrakeLabel.TextColor3 = if parked
		then Color3.fromRGB(255, 210, 69)
		elseif handbrake then Color3.fromRGB(255, 104, 91)
		else Color3.fromRGB(190, 195, 205)

	local healthFraction = if maximumHealth > 0 then math.clamp(health / maximumHealth, 0, 1) else 0
	healthFill.Size = UDim2.fromScale(healthFraction, 1)
	healthFill.BackgroundColor3 = if healthFraction > 0.5
		then Color3.fromRGB(81, 220, 112)
		elseif healthFraction > 0.25 then Color3.fromRGB(255, 200, 70)
		else Color3.fromRGB(255, 91, 91)
	healthLabel.Text = `CAR {math.floor(health)} / {math.floor(maximumHealth)}`
end

return table.freeze(VehicleHudController)
