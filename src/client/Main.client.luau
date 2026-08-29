--!strict

local Controllers = script.Parent:WaitForChild("Controllers")
local HudController = require(Controllers:WaitForChild("HudController"))
local VehicleController = require(Controllers:WaitForChild("VehicleController"))
local VehicleHudController = require(Controllers:WaitForChild("VehicleHudController"))

HudController.Start()
VehicleHudController.Start()
VehicleController.Start()
