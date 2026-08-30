--!strict

-- Shared store tuning. The server owns all robbery outcomes; clients may use
-- these values later for presentation, but never to decide rewards.
local RobberyLocationConfig = require(script.Parent.RobberyLocationConfig)

export type StoreSettings = {
	DisplayName: string,
	ActionText: string,
	Cost: number,
	Reward: number,
	Duration: number,
	Cooldown: number,
	PromptDistance: number,
	MaximumDistance: number,
	HoldDuration: number,
	CrimeId: string,
}

local stores: { [string]: StoreSettings } = {
	QuickStop = {
		DisplayName = "Quick Stop",
		ActionText = "Rob Register",
		Cost = 50,
		Reward = 250,
		Duration = 8,
		Cooldown = 20,
		PromptDistance = 8,
		MaximumDistance = 13,
		HoldDuration = 0.5,
		CrimeId = "StoreRobbery",
	},
}

for _, location in RobberyLocationConfig.Locations do
	stores[location.Id] = {
		DisplayName = location.DisplayName,
		ActionText = location.ActionText,
		Cost = location.Cost,
		Reward = location.Reward,
		Duration = location.Duration,
		Cooldown = location.Cooldown,
		PromptDistance = 9,
		MaximumDistance = 14,
		HoldDuration = 0.5,
		CrimeId = location.CrimeId,
	}
end

local RobberyConfig = {
	StoreIdAttribute = "RobberyStoreId",
	EnabledAttribute = "RobberyEnabled",
	TriggerRateLimit = 0.5,
	ResultMessageDuration = 4,
	Stores = stores,
}

return table.freeze(RobberyConfig)
