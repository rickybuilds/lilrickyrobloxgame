--!strict

local Controllers = script.Parent:WaitForChild("Controllers")
local HudController = require(Controllers:WaitForChild("HudController"))

HudController.Start()
