# Milestone 4 Studio Test

Milestones 1–3 are the stable baseline. Milestone 4 adds wanted severity, station-based police dispatch, vehicle/on-foot pursuit, arrest, confiscation, jail, and release. Police intentionally have perfect suspect knowledge until Milestone 5 adds sight and escape.

## Expected first-arrest result

| State | Expected value |
| --- | --- |
| First completed robbery | `$250`, wanted level 2 |
| Police origin | Police station response marker |
| Arrest requirement | Officer nearby for about 1.5 seconds while suspect is slow |
| Confiscation | 20% of robbery proceeds (`$50`) |
| After arrest | `$200`, wanted level 0 |
| Jail | 5 seconds, followed by release beside the police station |

## Single-player pursuit test

- [ ] Open `build/Milestone4.rbxlx` and press **Play**.
- [ ] Spawn with `$0`, five empty wanted stars, and the stable red player car.
- [ ] Complete the Quick Stop robbery; money becomes `$250` and wanted shows `★★☆☆☆`.
- [ ] Confirm one white-and-blue police cruiser appears at the police station, not beside the store.
- [ ] Enter the player car and drive; the cruiser pursues and its red/blue roof lights alternate.
- [ ] Confirm the police car does not immediately teleport, fly, or fall through the map.
- [ ] Stop in an open area and exit the player car.
- [ ] Confirm the cruiser slows, parks, and a blocky officer appears beside it.
- [ ] Move around a building; the officer follows on foot instead of walking straight through solid walls.
- [ ] Re-enter the player car before arrest; the officer should return to the cruiser and resume vehicle pursuit.
- [ ] Stop and exit again, then allow the officer to remain close for about 1.5 seconds.
- [ ] Confirm the player is arrested rather than killed.
- [ ] Confirm wanted clears to zero and money changes from `$250` to `$200`.
- [ ] Confirm the player appears in the jail for a five-second HUD countdown.
- [ ] Confirm release occurs outside the jail/police station and normal movement returns.
- [ ] Confirm the assigned officer and cruiser are cleaned up after arrest.
- [ ] Confirm no replacement police unit appears while wanted is zero.

## Respawn and regression test

- [ ] Commit another robbery and confirm police dispatch again.
- [ ] Reset while wanted; wanted remains and the existing unit resumes pursuit after respawn.
- [ ] Confirm the robbery register still cancels, pays once, and enforces cooldown.
- [ ] Confirm the red car still drives, parks, exits without spinning, and shows correctly steered wheels.
- [ ] Confirm road/store surfaces remain stable with no falling or visual floor flicker.
- [ ] Confirm Studio Output has no red client or server errors.

## Two-client test on one laptop

Use Studio's **Test** tab, choose **Server & Clients**, set player count to `2`, and start the test.

- [ ] Both players begin with independent money and wanted state.
- [ ] Player 1 completes a robbery and receives a unit targeted only at Player 1.
- [ ] After cooldown, Player 2 completes a robbery and receives a second independently targeted unit.
- [ ] Each cruiser begins at a different available station response marker.
- [ ] Police do not switch targets when the two players cross paths.
- [ ] Arresting Player 1 changes only Player 1's money, wanted level, jail state, and police unit.
- [ ] Player 2's wanted level and pursuing unit remain active.
- [ ] Arresting Player 2 resolves their state independently.
- [ ] Ending the session produces no client or server script errors.

Milestone 4 passes only after both pursuit modes, arrest, jail, and multiplayer isolation work. Search and escape are tested separately in Milestone 5.
