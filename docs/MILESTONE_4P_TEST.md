# Milestone 4P Police Station Polish Test

Milestone 4 gameplay is the committed stable baseline. This build polishes the generated police station, adds four-cell arrest placement, and renames the player-facing vehicle to **Gleep Glorp**. Pursuit, wanted, economy, and driving behavior remain unchanged.

## Visual and exploration test

- [ ] Open `build/Milestone4P.rbxlx` and press **Play**.
- [ ] Find a clearly recognizable police station instead of the previous solid rectangular shell.
- [ ] Confirm the facade has a **POLICE** sign, red/blue sign lights, glass, and an entrance canopy.
- [ ] From outside, confirm the glass lobby doors say **ENTER**.
- [ ] Walk through the glass entrance without colliding with an invisible wall.
- [ ] From inside, turn toward the doors and confirm they say **EXIT**.
- [ ] Explore the lobby and identify the front desk and benches.
- [ ] Confirm two open garage bays are labeled **UNIT 1** and **UNIT 2**.
- [ ] Confirm marked yellow response lanes lead from inside the garages toward the driveway.
- [ ] Find the **HOLDING CELLS** detention wing fully inside the station.
- [ ] Confirm there are four separate cells labeled **CELL 1** through **CELL 4**.
- [ ] Confirm each cell is enclosed by walls, ceiling, dividers, and front bars with no walk-through gap.
- [ ] Confirm there is no floor flicker in the lobby, garages, or holding-cell wing.
- [ ] Approach the player car and confirm its drive/ride prompt calls it **Gleep Glorp**.

## Gameplay regression test

- [ ] Complete a Quick Stop robbery and reach `$250` with wanted level 2.
- [ ] Confirm the police cruiser appears outside a marked garage bay without touching the station.
- [ ] Confirm the cruiser can immediately begin pursuit without becoming stuck on decorations.
- [ ] Complete vehicle pursuit, officer dismount, on-foot pursuit, and arrest.
- [ ] Confirm arrest still leaves `$200`, clears wanted, and produces the five-second jail countdown inside one numbered cell.
- [ ] During the countdown, confirm the arrested player cannot walk or leave the enclosed cell.
- [ ] Confirm release occurs outside the station and normal movement returns.
- [ ] In an optional two-client test, confirm two arrested players occupy different available cells.
- [ ] Drive the player car across the station driveway and around the jail without sinking, falling, or jittering.
- [ ] Confirm Studio Output has no red client or server errors.

If this passes, commit 4P separately and begin Milestone 5 without expanding the apartments or Community Center yet.
