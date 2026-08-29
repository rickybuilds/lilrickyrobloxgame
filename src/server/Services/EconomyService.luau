--!strict

local Players = game:GetService("Players")

local PlayerStateService = require(script.Parent.PlayerStateService)

local EconomyService = {}
local robberyProceeds: { [Player]: number } = {}
local started = false

function EconomyService.Start()
	assert(not started, "EconomyService.Start may only be called once")
	started = true

	Players.PlayerRemoving:Connect(function(player)
		robberyProceeds[player] = nil
	end)
end

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
	if string.sub(reason, 1, 8) == "robbery:" then
		robberyProceeds[player] = (robberyProceeds[player] or 0) + amount
	end
	print(`Economy: awarded ${amount} to {player.Name} ({reason}); balance ${balance}`)
	return balance
end

function EconomyService.GetRobberyProceeds(player: Player): number
	return math.min(robberyProceeds[player] or 0, PlayerStateService.GetMoney(player))
end

function EconomyService.ConfiscateRobberyProceeds(player: Player, fraction: number): number
	assert(fraction >= 0 and fraction <= 1, "Confiscation fraction must be between zero and one")
	if player.Parent ~= Players then
		return 0
	end

	local available = EconomyService.GetRobberyProceeds(player)
	local confiscated = math.floor(available * fraction + 0.5)
	if confiscated <= 0 then
		return 0
	end

	robberyProceeds[player] = math.max(0, available - confiscated)
	PlayerStateService.RemoveMoney(player, confiscated)
	print(`Economy: confiscated ${confiscated} of robbery proceeds from {player.Name}`)
	return confiscated
end

-- Escaping or completing an arrest resolves all remaining hot proceeds. The
-- money stays in the player's balance, but a later unrelated arrest cannot
-- confiscate it again.
function EconomyService.SecureRobberyProceeds(player: Player): number
	if player.Parent ~= Players then
		return 0
	end
	local secured = EconomyService.GetRobberyProceeds(player)
	robberyProceeds[player] = 0
	if secured > 0 then
		print(`Economy: secured ${secured} of robbery proceeds for {player.Name}`)
	end
	return secured
end

return table.freeze(EconomyService)
