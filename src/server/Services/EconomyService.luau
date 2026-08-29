--!strict

local Players = game:GetService("Players")

local PlayerStateService = require(script.Parent.PlayerStateService)

local EconomyService = {}

-- All money enters the game through a named server-side transaction. Later,
-- this is the natural place to add saving, analytics, and anti-abuse logging.
function EconomyService.AwardMoney(player: Player, amount: number, reason: string): number?
	assert(amount > 0 and amount % 1 == 0, "Money awards must be positive whole numbers")
	assert(amount <= 10_000, "A single MVP money award is unexpectedly large")
	assert(#reason > 0 and #reason <= 50, "Money awards require a short reason")

	if player.Parent ~= Players then
		return nil
	end

	local balance = PlayerStateService.AddMoney(player, amount)
	print(`Economy: awarded ${amount} to {player.Name} ({reason}); balance ${balance}`)
	return balance
end

return table.freeze(EconomyService)
