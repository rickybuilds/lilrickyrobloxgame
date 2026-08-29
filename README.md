# Ricky's City

An age-appropriate Roblox open-world driving and cops-vs-criminals game being built one playable milestone at a time.

## Current build: Milestone 5 — Escape and Wanted Decay Test Build

Milestone 4P is the stable baseline. Milestone 5 completes the Phase 1 escape loop with:

- Server-raycast police sight checks
- Dispatch tracking that gives distant response units time to arrive
- Last-seen-position searching instead of perfect suspect knowledge
- A HUD escape countdown that resets when police see the suspect again
- Per-star wanted decay while the suspect remains hidden
- Police return-to-station behavior and safe timeout cleanup
- Independent pursuit and escape state for each player

At the default robbery wanted level of 2, remaining hidden removes the first star after 10 seconds and the final star after another 8 seconds. Arrest remains an alternate way to end the pursuit.

## Open it in Roblox Studio

This project uses [Rojo](https://rojo.space/) so the readable Luau source files in this repository map cleanly into Roblox Studio.

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. Open a new **Baseplate** place in Roblox Studio.
3. In a terminal opened in this folder, run `rojo serve`.
4. In Studio, open the Rojo plugin, connect to the running project, and click **Sync In**.
5. Press **Play**. Do not use **Run**, because the HUD needs a local player.

The city is created when the server starts. It appears under `Workspace > GameWorld` while playing.

## Milestone 5 test checklist

- [ ] Rob the Quick Stop, keep `$250`, and receive wanted level 2.
- [ ] Police respond from the station and the HUD displays pursuit instructions.
- [ ] Breaking line of sight changes the HUD to **HIDDEN** with a countdown.
- [ ] Being seen again restores pursuit and resets all hidden progress.
- [ ] Staying hidden removes wanted stars one at a time until level 0.
- [ ] The `$250` robbery reward remains after a successful escape.
- [ ] Police stop their siren, return toward the station, and clean up safely.
- [ ] Arrest, jail, release, driving, robbery, and two-client independence still work.
- [ ] The Output window has no red errors.

See [docs/MILESTONE_5_TEST.md](docs/MILESTONE_5_TEST.md) for the complete test procedure.
