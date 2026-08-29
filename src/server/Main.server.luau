--!strict

local Services = script.Parent.Services

local ArrestService = require(Services.ArrestService)
local EconomyService = require(Services.EconomyService)
local PlayerStateService = require(Services.PlayerStateService)
local PoliceService = require(Services.PoliceService)
local RobberyService = require(Services.RobberyService)
local VehicleService = require(Services.VehicleService)
local WantedService = require(Services.WantedService)
local WorldService = require(Services.WorldService)

-- World generation happens before player state setup so the spawn exists as soon
-- as players join a local or published server.
WorldService.Start()
PlayerStateService.Start()
EconomyService.Start()
WantedService.Start()
VehicleService.Start()
ArrestService.Start()
RobberyService.Start()
PoliceService.Start()

print("Ricky's City server started: Milestone 5 escape and wanted decay test build")
