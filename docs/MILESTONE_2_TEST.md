# Milestone 2 Studio Test

Milestone 1 is the stable baseline. This checklist tests only the new vehicle systems and verifies that the baseline still works.

## Controls

| Action | Keyboard | Gamepad / touch foundation |
| --- | --- | --- |
| Enter driver seat | `E` at the prompt | Prompt button |
| Enter passenger seat | `R` at the **Ride** prompt | Prompt button |
| Accelerate | `W` | Vehicle throttle |
| Brake / reverse | `S` | Vehicle throttle |
| Steer | `A` / `D` | Vehicle steering |
| Handbrake | Hold `Space` | `X` / `BRAKE` touch button |
| Park / unpark | `P` | `Y` / `PARK` touch button |
| Exit | `E` while seated | `B` / `EXIT` touch button |

## Single-player test

- [ ] Open the newest `build/Milestone2.rbxlx` and press **Play**.
- [ ] Spawn on the green player pad with the original HUD intact.
- [ ] Find one red car at the blue vehicle pad.
- [ ] Walk near the driver's side and activate **Drive**.
- [ ] The character sits in the driver seat and the speedometer appears.
- [ ] Drive forward, reverse, steer both directions, brake, and use the handbrake.
- [ ] Press `P`; the HUD displays `PARKED` and the car comes to a stop.
- [ ] Pressing `W` or `S` automatically releases park and allows movement again.
- [ ] The car stays reasonably upright and does not fall through the road.
- [ ] Speed changes on the speedometer; health remains `100 / 100`.
- [ ] Press `E`; the character exits safely beside the car.
- [ ] Reset the character and confirm the original HUD and spawn still work.
- [ ] Confirm Studio Output has no red errors.

## Two-client test

- [ ] Start **Server & Clients** with two clients.
- [ ] Both players retain their independent Milestone 1 HUDs.
- [ ] Player 1 enters through **Drive**.
- [ ] Player 2 enters through **Ride**.
- [ ] Once seated, neither player sees the outside **Drive** or **Ride** prompts.
- [ ] The passenger sees `E • EXIT VEHICLE`; the driver HUD includes `E EXIT`.
- [ ] Player 1 controls the car; Player 2 cannot steer or accelerate it.
- [ ] Each player can exit safely.
- [ ] Simultaneous driver prompt attempts result in only one driver.
- [ ] After the driver exits, the other player can become the driver.
- [ ] Ending the session produces no client or server script errors.

Do not proceed to Milestone 3 until the car is enjoyable enough to drive and every functional issue discovered here has been recorded or corrected.
