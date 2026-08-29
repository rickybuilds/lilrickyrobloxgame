# Ricky's City

An age-appropriate Roblox open-world driving and cops-vs-criminals game being built one playable milestone at a time.

## Current build: Milestone 3 — Quick Stop Robbery Test Build

Milestones 1 and 2 are the stable baseline. The current test build adds:

- One server-validated robbery at the Quick Stop register
- An eight-second stay-near-the-register countdown
- Cancellation with no payout when the robber leaves early
- A single server-issued `$250` reward on success
- A shared 20-second store cooldown
- Robbery progress in the existing HUD and over the register

It intentionally does **not** raise wanted level or spawn police yet. Wanted escalation and police pursuit are Milestone 4, after this robbery/economy layer passes testing.

## Open it in Roblox Studio

This project uses [Rojo](https://rojo.space/) so the readable Luau source files in this repository map cleanly into Roblox Studio.

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. Open a new **Baseplate** place in Roblox Studio.
3. In a terminal opened in this folder, run `rojo serve`.
4. In Studio, open the Rojo plugin, connect to the running project, and click **Sync In**.
5. Press **Play**. Do not use **Run**, because the HUD needs a local player.

The city is created when the server starts. It appears under `Workspace > GameWorld` while playing.

## Milestone 3 test checklist

- [ ] The Quick Stop register shows **READY** and a **Rob Register** prompt.
- [ ] Starting a robbery changes the HUD to an eight-second countdown.
- [ ] Walking away early cancels the robbery and leaves money at `$0`.
- [ ] Staying near the register completes it and awards exactly `$250` once.
- [ ] The register enters a visible 20-second cooldown, then returns to **READY**.
- [ ] In a two-client test, only one player can own the active robbery.
- [ ] The stable city, car, seats, controls, vehicle HUD, and respawn still work.
- [ ] The Output window has no red errors.

See [docs/MILESTONE_3_TEST.md](docs/MILESTONE_3_TEST.md) for the complete test procedure.
