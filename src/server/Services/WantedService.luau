--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local WantedConfig = require(ReplicatedStorage.Shared.Config.WantedConfig)
local PlayerStateService = require(script.Parent.PlayerStateService)

local WantedService = {}
local started = false

function WantedService.Start()
	assert(not started, "WantedService.Start may only be called once")
	started = true
end

function WantedService.GetLevel(player: Player): number
	local value = player:GetAttribute(GameConfig.Attributes.WantedLevel)
	if typeof(value) ~= "number" then
		return GameConfig.Wanted.MinimumLevel
	end

	return math.clamp(
		math.floor(value),
		GameConfig.Wanted.MinimumLevel,
		GameConfig.Wanted.MaximumLevel
	)
end

function WantedService.ReportCrime(player: Player, crimeId: string): number?
	assert(started, "WantedService must be started before crimes are reported")
	assert(#crimeId > 0 and #crimeId <= 40, "Crime ids must be short non-empty strings")

	if player.Parent ~= Players then
		return nil
	end

	local settings = WantedConfig.Crimes[crimeId]
	assert(settings, `Unknown crime id: {crimeId}`)

	local currentLevel = WantedService.GetLevel(player)
	local newLevel = if currentLevel < settings.MinimumLevel
		then settings.MinimumLevel
		else currentLevel + settings.RepeatIncrease

	return PlayerStateService.SetWantedLevel(player, newLevel)
end

function WantedService.ClearWanted(player: Player): number?
	assert(started, "WantedService must be started before wanted is cleared")
	if player.Parent ~= Players then
		return nil
	end

	return PlayerStateService.SetWantedLevel(player, GameConfig.Wanted.MinimumLevel)
end

function WantedService.ReduceWanted(player: Player, amount: number): number?
	assert(started, "WantedService must be started before wanted is reduced")
	assert(amount > 0 and amount % 1 == 0, "Wanted reduction must be a positive whole number")
	if player.Parent ~= Players then
		return nil
	end

	return PlayerStateService.SetWantedLevel(player, WantedService.GetLevel(player) - amount)
end

return table.freeze(WantedService)
