# Ricky's City

An age-appropriate Roblox open-world driving and cops-vs-criminals game being built one playable milestone at a time.

## Current build: Milestone 4P — Police Station Polish Test Build

Milestone 4 police gameplay is the stable baseline. This focused polish build adds:

- An explorable police lobby and front desk
- A recognizable facade, canopy, windows, and illuminated police sign
- Two open garage bays with marked response lanes
- An indoor detention wing with four enclosed, numbered holding cells
- ENTER/EXIT labels on the correct sides of the lobby doors
- The player vehicle display name **Gleep Glorp**
- Thin visual floors that preserve the stable single-surface vehicle physics

Wanted, pursuit, economy, and driving behavior are unchanged from the committed Milestone 4 baseline. Arrested players are now assigned to one of the four indoor cells.

## Open it in Roblox Studio

This project uses [Rojo](https://rojo.space/) so the readable Luau source files in this repository map cleanly into Roblox Studio.

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. Open a new **Baseplate** place in Roblox Studio.
3. In a terminal opened in this folder, run `rojo serve`.
4. In Studio, open the Rojo plugin, connect to the running project, and click **Sync In**.
5. Press **Play**. Do not use **Run**, because the HUD needs a local player.

The city is created when the server starts. It appears under `Workspace > GameWorld` while playing.

## Milestone 4P test checklist

- [ ] The station has a recognizable entrance, lobby, garage bays, response lanes, and indoor holding cells.
- [ ] Players can walk through the lobby entrance and explore the front desk area.
- [ ] The lobby doors read **ENTER** outside and **EXIT** inside.
- [ ] Four enclosed cells labeled **CELL 1** through **CELL 4** are inside the station.
- [ ] The car interaction prompt calls the vehicle **Gleep Glorp**.
- [ ] Police cruisers spawn outside the two marked garage bays without clipping the facade.
- [ ] Vehicles remain stable across the station driveway and jail area.
- [ ] The complete robbery, pursuit, arrest, confiscation, jail, and release loop still works.
- [ ] The Output window has no red errors.

See [docs/MILESTONE_4P_TEST.md](docs/MILESTONE_4P_TEST.md) for the complete test procedure.
