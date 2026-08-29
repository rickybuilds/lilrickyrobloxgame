# Milestone 5 Escape and Wanted Decay Test

Milestone 4P is the committed stable baseline. Milestone 5 completes the Phase 1 loop with server-authoritative sight, searching, per-star wanted decay, and police return behavior.

## Main escape loop

- [ ] Open `build/Milestone5.rbxlx` and press **Play**.
- [ ] Enter **Gleep Glorp**, drive to the Quick Stop, and complete one robbery.
- [ ] Confirm money becomes `$250` and wanted becomes 2 stars.
- [ ] Confirm a police cruiser responds from the station rather than spawning beside the player.
- [ ] During active pursuit, confirm the HUD says **POLICE PURSUIT • Break line of sight!**.
- [ ] Let the cruiser get close enough to establish contact, then drive behind a solid building or far beyond sight range.
- [ ] Confirm police continue toward the last-seen location rather than following perfectly through the obstruction.
- [ ] After the short lost-sight grace period, confirm the HUD changes to **HIDDEN** and shows a countdown.
- [ ] Before the countdown finishes, move back into police sight.
- [ ] Confirm the HUD returns to pursuit and the hidden countdown is reset.
- [ ] Break sight again and remain hidden for the full countdown.
- [ ] Confirm wanted falls from 2 stars to 1 after about 10 hidden seconds.
- [ ] Remain hidden and confirm wanted falls from 1 star to 0 after another 8 hidden seconds.
- [ ] Confirm the HUD briefly says the escape succeeded and money remains `$250`.
- [ ] Confirm police siren lights turn off, the unit heads toward its station marker, and it safely disappears on arrival or after its cleanup timeout.

## Arrest regression

- [ ] Start another robbery and allow police to maintain sight.
- [ ] Stop and exit the car so the officer can complete an arrest.
- [ ] Confirm wanted clears, `$50` is confiscated from that robbery's hot proceeds, and the player is placed in one of the four indoor cells for five seconds.
- [ ] Confirm release outside the station restores normal movement.

## Multiplayer independence

- [ ] Start a two-player local server test.
- [ ] Give both players wanted levels by completing robberies in turn.
- [ ] Hide one player while the other remains visible.
- [ ] Confirm only the hidden player receives an escape countdown.
- [ ] Confirm spotting one player does not reset the other player's countdown.
- [ ] Confirm each player's stars clear independently and each keeps their own successful robbery reward.

## Baseline regression

- [ ] The station still contains four enclosed indoor holding cells.
- [ ] The lobby doors still read **ENTER** outside and **EXIT** inside.
- [ ] Gleep Glorp can still be driven, parked, exited, and entered as driver or passenger.
- [ ] The Quick Stop countdown, cancellation, payout, and cooldown still work.
- [ ] Respawning does not mix HUD state between players.
- [ ] Studio Output has no red client or server errors.

If every item passes, Milestone 5 completes the Phase 1 MVP.
