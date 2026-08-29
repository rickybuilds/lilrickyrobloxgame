# Milestone 6C — Arrival, Rentals, and City Economy Test

Open `build/Milestone6C_ArrivalEconomy.rbxlx` in Roblox Studio and press **Play**.

## Arrival and spawn selection

- [ ] Spawn inside the enclosed sky arrival terminal without falling out.
- [ ] HUD money begins at `$150` with zero wanted stars.
- [ ] See five gates: Downtown, Northside, Eastside, Southside, and Westside.
- [ ] Hold `E` at a gate and arrive at the correct district pad.
- [ ] The chosen district displays briefly on the activity HUD.
- [ ] Reset the character and respawn at the chosen district instead of the arrival terminal.
- [ ] Leave and rejoin the server; because data is still session-only, choose a district again.

## Rental test

Repeat the discovery portion at multiple gates.

- [ ] Every district destination has a visible `RENT GLEEP GLORP $100` kiosk within interaction range.
- [ ] Hold `E` with `$150`: one rental appears on that district's marked car pad.
- [ ] Balance becomes exactly `$50`.
- [ ] The renter can drive and exit normally.
- [ ] Another player cannot take the driver's seat.
- [ ] Another player can ride in the passenger seat.
- [ ] With less than `$100`, the kiosk refuses the rental and deducts nothing.
- [ ] After earning more money, renting again charges `$100` and replaces the player's previous rental.
- [ ] Two players can own separate rentals without overwriting each other.
- [ ] A player's rental disappears when that player leaves the server.

## Economy test

- [ ] Tier 1 robberies advertise and pay `$50`–`$150`.
- [ ] Tier 2 robberies advertise and pay `$200`–`$400`.
- [ ] Tier 3 robberies advertise and pay `$600`–`$1,000`.
- [ ] The original Quick Stop still pays `$250`.
- [ ] Cancelling a robbery awards nothing.
- [ ] Arrest confiscation and successful-escape money behavior remain correct.

## Expanded police network

- [ ] Find the original Downtown police station.
- [ ] Find North, East, South, West, and Southeast precincts.
- [ ] Each satellite precinct has a signed building and two nearby response lanes.
- [ ] Commit crimes in several districts and confirm police originate from a sensible available precinct.
- [ ] Police never spawn directly beside the wanted player.
- [ ] Repeat robbery dispatch, pursuit, search, escape, arrest, and return behavior still works.

## Regression and multiplayer

- [ ] Two simulated clients choose different districts and retain independent respawns.
- [ ] Money, wanted level, rental ownership, and robbery state remain independent.
- [ ] Driving, vehicle health, parking, exit, HUD, jail, and police remain functional.
- [ ] No vehicle falls through the city ground.
- [ ] Roblox Studio Output has no red client or server errors.
