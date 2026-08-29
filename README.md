# Ricky's City

An age-appropriate Roblox open-world driving and cops-vs-criminals game being built one playable milestone at a time.

## Current build: Milestone 2 — Drivable Car Test Build

Milestone 1 is the stable baseline. The current test build adds:

- One original arcade-style car generated from safe Parts
- Server-validated driver and passenger entry prompts
- Acceleration, braking/reverse, steering, suspension, grip, and handbrake
- Server-controlled seat assignment, health, exits, and network ownership
- A driver-only speedometer and vehicle health display
- Keyboard, gamepad, and touch-ready action bindings

It intentionally does **not** include robbery payout or police AI yet. Those remain later milestones.

## Open it in Roblox Studio

This project uses [Rojo](https://rojo.space/) so the readable Luau source files in this repository map cleanly into Roblox Studio.

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. Open a new **Baseplate** place in Roblox Studio.
3. In a terminal opened in this folder, run `rojo serve`.
4. In Studio, open the Rojo plugin, connect to the running project, and click **Sync In**.
5. Press **Play**. Do not use **Run**, because the HUD needs a local player.

The city is created when the server starts. It appears under `Workspace > GameWorld` while playing.

## Milestone 2 test checklist

- [ ] The red car appears over the blue vehicle pad without falling through the road.
- [ ] The nearby **Drive** prompt seats one player in the driver seat.
- [ ] `W/S` accelerates, brakes, and reverses; `A/D` steers.
- [ ] Holding `Space` engages the handbrake and updates the vehicle HUD.
- [ ] `P` parks the car; pressing the throttle automatically releases park.
- [ ] The speedometer appears only for the driver and changes while moving.
- [ ] Pressing `E` exits beside the vehicle instead of underneath it.
- [ ] A second player can use **Ride** but cannot control the car.
- [ ] Two players cannot occupy the driver seat simultaneously.
- [ ] Resetting or leaving returns vehicle network control safely.
- [ ] The Milestone 1 HUD and respawn behavior still work.
- [ ] The Output window has no red errors.

See [docs/MILESTONE_2_TEST.md](docs/MILESTONE_2_TEST.md) for the complete controls and test procedure.
