--!strict

export type CrimeSettings = {
	MinimumLevel: number,
	RepeatIncrease: number,
}

-- Crime tuning is data-driven so later activities can report crimes without
-- embedding wanted-level rules in robbery, combat, or vehicle code.
local crimes: { [string]: CrimeSettings } = {
	StoreRobbery = {
		MinimumLevel = 2,
		RepeatIncrease = 1,
	},

	-- Reserved definitions for later milestones. Nothing reports these yet.
	PropertyDamage = {
		MinimumLevel = 1,
		RepeatIncrease = 1,
	},
	Assault = {
		MinimumLevel = 3,
		RepeatIncrease = 1,
	},
}

local WantedConfig = {
	Crimes = crimes,
}

return table.freeze(WantedConfig)
