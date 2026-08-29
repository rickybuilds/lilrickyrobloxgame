--!strict

-- Shared store tuning. The server owns all robbery outcomes; clients may use
-- these values later for presentation, but never to decide rewards.
export type StoreSettings = {
	DisplayName: string,
	Reward: number,
	Duration: number,
	Cooldown: number,
	PromptDistance: number,
	MaximumDistance: number,
	HoldDuration: number,
}

local stores: { [string]: StoreSettings } = {
	QuickStop = {
		DisplayName = "Quick Stop",
		Reward = 250,
		Duration = 8,
		Cooldown = 20,
		PromptDistance = 8,
		MaximumDistance = 13,
		HoldDuration = 0.5,
	},
}

local RobberyConfig = {
	StoreIdAttribute = "RobberyStoreId",
	EnabledAttribute = "RobberyEnabled",
	TriggerRateLimit = 0.5,
	ResultMessageDuration = 4,
	Stores = stores,
}

return table.freeze(RobberyConfig)
