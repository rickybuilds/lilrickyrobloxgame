# Ricky's City

An age-appropriate Roblox open-world driving and cops-vs-criminals game being built one playable milestone at a time.

## Current build: Milestone 1 — Playable Foundation

Milestone 1 includes:

- A generated blockout city with roads and sidewalks
- A player spawn, police station, convenience-store shell, and future vehicle spawn
- Server-owned session money and wanted level
- A basic HUD for money, wanted level, and activity status
- Clean service/controller folders ready for the later systems

It intentionally does **not** include a drivable car, robbery payout, or police AI yet. Those are separate milestones with their own tests.

## Open it in Roblox Studio

This project uses [Rojo](https://rojo.space/) so the readable Luau source files in this repository map cleanly into Roblox Studio.

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. Open a new **Baseplate** place in Roblox Studio.
3. In a terminal opened in this folder, run `rojo serve`.
4. In Studio, open the Rojo plugin, connect to the running project, and click **Sync In**.
5. Press **Play**. Do not use **Run**, because the HUD needs a local player.

The city is created when the server starts. It appears under `Workspace > GameWorld` while playing.

## Milestone 1 test checklist

- [ ] The player spawns on a green pad beside the main intersection.
- [ ] The city has two crossing roads, sidewalks, simple buildings, a convenience store, and a police station.
- [ ] The top-left HUD shows `$0` and wanted level `0`.
- [ ] The bottom activity banner says `Explore the city`.
- [ ] Starting a two-player local test gives each player a separate HUD and server-owned state.
- [ ] The Output window has no red errors.

See [docs/PHASE_1_PLAN.md](docs/PHASE_1_PLAN.md) for the architecture and full MVP milestone plan.

