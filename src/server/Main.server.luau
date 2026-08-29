--!strict

local Services = script.Parent.Services

local PlayerStateService = require(Services.PlayerStateService)
local VehicleService = require(Services.VehicleService)
local WorldService = require(Services.WorldService)

-- World generation happens before player state setup so the spawn exists as soon
-- as players join a local or published server.
WorldService.Start()
PlayerStateService.Start()
VehicleService.Start()

print("Ricky's City server started: Milestone 2 test build")
