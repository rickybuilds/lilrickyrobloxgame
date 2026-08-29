# Ricky's City

An age-appropriate Roblox open-world driving and cops-vs-criminals game being built one playable milestone at a time.

## Current build: Milestone 4 — Police Pursuit Test Build

Milestones 1–3 and the 4A wanted foundation are the stable baseline. The current test build adds:

- Police dispatch from reserved police-station response markers
- One independently targeted police unit per wanted player
- A server-driven police cruiser using the existing arcade chassis
- Vehicle pursuit, obstacle checks, stuck recovery, and flashing lights
- On-foot officer pathfinding and reboarding behavior
- Server-validated arrest, robbery-money confiscation, jail, and release

Police have perfect suspect knowledge in this milestone. Sight, search, escape, and wanted decay intentionally remain Milestone 5.

## Open it in Roblox Studio

This project uses [Rojo](https://rojo.space/) so the readable Luau source files in this repository map cleanly into Roblox Studio.

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. Open a new **Baseplate** place in Roblox Studio.
3. In a terminal opened in this folder, run `rojo serve`.
4. In Studio, open the Rojo plugin, connect to the running project, and click **Sync In**.
5. Press **Play**. Do not use **Run**, because the HUD needs a local player.

The city is created when the server starts. It appears under `Workspace > GameWorld` while playing.

## Milestone 4 test checklist

- [ ] Completing a robbery raises wanted to level 2 and dispatches police from the station.
- [ ] The police cruiser pursues the correct player and never spawns beside them.
- [ ] When the suspect stops and exits, the officer dismounts and pursues on foot.
- [ ] A sustained close-range capture arrests rather than kills the player.
- [ ] Arrest clears wanted, confiscates `$50` from the first `$250`, and jails the player for five seconds.
- [ ] Two wanted clients receive independently targeted units and arrest results.
- [ ] The stable city, player car, robbery, economy, HUD, and respawn still work.
- [ ] The Output window has no red errors.

See [docs/MILESTONE_4_TEST.md](docs/MILESTONE_4_TEST.md) for the complete test procedure.
