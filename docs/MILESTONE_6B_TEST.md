# Milestone 6B — Robbery City Test

Open `build/Milestone6B_RobberyCity.rbxlx` in Roblox Studio and press **Play**.

## What this build contains

- The complete 1600×1600 Mega City
- Forty new robbery locations distributed across forty outer-district blocks
- The original Quick Stop robbery, for forty-one total robbery targets
- Fifteen Tier 1 jobs worth $120–$200 with 5–7 second timers
- Fifteen Tier 2 jobs worth $250–$330 with 8–10 second timers
- Ten Tier 3 jobs worth $450–$610 with 12–14 second timers
- Independent 30–85 second location cooldowns
- Server-authoritative payouts, wanted severity, police dispatch, and cancellation

## Discovery test

- [ ] Drive the outer and middle districts and find signed robbery locations.
- [ ] Confirm storefront, kiosk, arcade, industrial, and vault designs are visibly different.
- [ ] Confirm each sign displays its tier and exact reward.
- [ ] Confirm the target's prompt uses a location-specific action.
- [ ] In Explorer, confirm `Workspace > GameWorld > Landmarks > CityRobberyLocations` reports `LocationCount = 40`.

## Tier and payout test

Begin each test with no wanted stars.

- [ ] Complete a Tier 1 job: receive its advertised reward and reach wanted level 1.
- [ ] Escape or get arrested until wanted clears.
- [ ] Complete a Tier 2 job: receive its advertised reward and reach wanted level 2.
- [ ] Clear wanted again.
- [ ] Complete a Tier 3 job: receive its advertised reward and reach wanted level 3.
- [ ] Confirm police originate from the station and pursue the correct player.

## Validation and cooldown test

- [ ] Start a robbery and walk away: it cancels with no payout.
- [ ] Complete a robbery: its prompt disables and its own cooldown counts down.
- [ ] While that target cools down, another location remains available.
- [ ] Revisit the first target after cooldown and confirm it becomes ready again.
- [ ] Attempt to start a second robbery while already robbing: the second one does not begin.

## Multiplayer test

Use Studio's two-player local server test on the same laptop.

- [ ] Both players can rob different locations simultaneously.
- [ ] Each player receives only their own reward and wanted level.
- [ ] Two players cannot rob the same active target together.
- [ ] Police units track the correct wanted player.
- [ ] Arrest, jail, escape, vehicle, and HUD behavior still work.

## Performance and regression test

- [ ] Driving remains responsive throughout the expanded city.
- [ ] Robbery status billboards appear only within a reasonable distance.
- [ ] Police can be re-dispatched after a previous escape.
- [ ] No vehicle falls through the continuous ground plane.
- [ ] Roblox Studio Output contains no red client or server errors.
