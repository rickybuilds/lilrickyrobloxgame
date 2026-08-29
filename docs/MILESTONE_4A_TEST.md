# Milestone 4A Studio Test

Milestones 1–3 are the stable baseline. This build tests only server-owned wanted severity. Police response intentionally begins in Milestone 4B.

## Expected wanted rules

| Event | Expected wanted level |
| --- | --- |
| Join or respawn before committing a crime | 0 |
| Cancel a robbery | Unchanged |
| Complete first store robbery | 2 |
| Complete another robbery while wanted | Current level + 1 |
| Continue completing robberies | Never greater than 5 |

## Single-player test

- [ ] Open `build/Milestone4A.rbxlx` and press **Play**.
- [ ] Spawn with `$0`, five empty wanted stars, and `Explore the city`.
- [ ] Start a robbery and leave the register early; money and wanted remain at zero.
- [ ] Complete a robbery; money becomes `$250` and wanted shows `★★☆☆☆`.
- [ ] Wait for the store cooldown and complete another robbery; money becomes `$500` and wanted shows `★★★☆☆`.
- [ ] Reset the character; wanted remains at level 3 and the HUD returns correctly.
- [ ] Confirm no police spawn yet; that is expected until Milestone 4B.
- [ ] Confirm the stable car, map collision, robbery cancellation, payout, and cooldown still work.
- [ ] Confirm Studio Output has no red client or server errors.

## Two-client test on one laptop

Use Studio's **Test** tab, choose **Server & Clients**, set the player count to `2`, and start the test.

- [ ] Both players begin at wanted level 0.
- [ ] Player 1 completes a robbery and reaches wanted level 2.
- [ ] Player 2 remains at wanted level 0.
- [ ] After cooldown, Player 2 completes a robbery and reaches wanted level 2 without changing Player 1.
- [ ] Resetting one player does not change either player's wanted level.
- [ ] Both clients retain independent money and activity status.
- [ ] Ending the session produces no client or server script errors.

Milestone 4A passes when both lists work. Do not proceed to police vehicle construction until this wanted foundation is stable.
