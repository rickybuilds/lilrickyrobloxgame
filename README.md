# Ricky's City

An age-appropriate Roblox open-world driving and cops-vs-criminals game being built one playable milestone at a time.

## Current build: Milestone 6C — Arrival, Rentals, and City Economy

Milestone 5 is the stable, complete Phase 1 gameplay baseline. Milestone 6C keeps the Robbery City and adds a proper arrival/economy loop:

- A 1600×1600 map with nine east–west and nine north–south streets
- A connected outer driving loop and 64 city blocks
- Eight narrow central alleys for shortcuts and escapes
- 126 new named commercial/residential buildings plus six police-station buildings
- An open ground-level parking garage, two parking lots, and parked prop cars
- A pocket park, benches, 81 streetlights, alley dumpsters, roughly 250 trees, and boundary guardrails
- Eighty-one invisible, named road nodes reserved for future NPC navigation
- Forty new robbery locations plus the original Quick Stop register
- Fifteen quick one-star jobs, fifteen standard two-star jobs, and ten high-value three-star jobs
- Five visual robbery styles: storefronts, kiosks, arcades, industrial lockups, and vault alcoves
- Unique location names, interaction text, targets, rewards, countdowns, and cooldowns
- An enclosed sky arrival terminal with five district-selection gates
- Session respawns at the chosen Downtown, Northside, Eastside, Southside, or Westside location
- A $100 Gleep Glorp rental kiosk at every district arrival point
- A $150 starting balance and robbery payouts ranging from $50 to $1,000
- Six total police stations and twelve reasonable response lanes around the enlarged city

All road, alley, sidewalk, parking-lot, and park skins remain non-collidable above one continuous ground plane, preserving the stable arcade vehicle physics.

## Open it in Roblox Studio

This project uses [Rojo](https://rojo.space/) so the readable Luau source files in this repository map cleanly into Roblox Studio.

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. Open a new **Baseplate** place in Roblox Studio.
3. In a terminal opened in this folder, run `rojo serve`.
4. In Studio, open the Rojo plugin, connect to the running project, and click **Sync In**.
5. Press **Play**. Do not use **Run**, because the HUD needs a local player.

The city is created when the server starts. It appears under `Workspace > GameWorld` while playing.

## Milestone 6C test checklist

- [ ] Spawn safely inside the arrival terminal with `$150`.
- [ ] Choose one of five gates and arrive beside that district's rental kiosk.
- [ ] Reset the character and confirm it respawns in the chosen district, not the terminal.
- [ ] Rent a Gleep Glorp for `$100` and confirm the balance becomes `$50`.
- [ ] Confirm another player cannot drive the rental but can use its passenger seat.
- [ ] Drive the complete outer loop and several interior streets without falling or sinking.
- [ ] Find multiple signed robbery locations throughout the outer districts.
- [ ] Confirm targets offer different actions such as grabbing tips, opening lockers, and cracking prize vaults.
- [ ] Complete one job from each tier and confirm its displayed reward and wanted response.
- [ ] Confirm leaving a robbery early cancels it and never awards money.
- [ ] Confirm each location has its own cooldown and another location can still be robbed.
- [ ] Use the expanded city to escape the responding police and keep the reward.
- [ ] Find the five satellite precincts and confirm police dispatch from a sensible nearby response lane.
- [ ] Confirm two players can rob different locations without sharing money or wanted state.
- [ ] The Output window has no red errors.

See [docs/MILESTONE_6C_TEST.md](docs/MILESTONE_6C_TEST.md) for the complete test procedure.
