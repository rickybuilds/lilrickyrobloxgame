# Milestone 3 Studio Test

Milestones 1 and 2 are the stable baseline. This checklist tests the Quick Stop robbery and economy layer without adding wanted level or police behavior yet.

## Expected tuning

| Rule | Milestone 3 value |
| --- | --- |
| Store | Quick Stop |
| Interaction | Hold `E` at **Rob Register** |
| Robbery time | 8 seconds |
| Successful reward | `$250` |
| Store cooldown | 20 seconds |
| Failure condition | Leave the register area, die/reset, enter a seat, or leave the server |

## Single-player test

- [ ] Open `build/Milestone3.rbxlx` and press **Play**.
- [ ] Spawn with `$0`, five empty wanted stars, and `Explore the city`.
- [ ] Confirm the stable red car still drives, parks, and exits correctly.
- [ ] Turn while moving, exit the driver seat, and confirm the unattended car settles without spinning.
- [ ] Steer left and right; both front wheels should visibly point in the direction the car turns.
- [ ] Drive from the road onto the concrete in front of Quick Stop; the surfaces should be level and the car should not sink or clip into either one.
- [ ] Enter the Quick Stop and walk to the register behind the counter.
- [ ] Confirm the register shows **READY** and offers **Rob Register**.
- [ ] Hold `E`; the register changes to **ROBBERY IN PROGRESS** and the HUD counts down from 8 seconds.
- [ ] For the first attempt, walk away from the register before time expires.
- [ ] Confirm the HUD says the robbery was cancelled and money remains `$0`.
- [ ] Return and complete a full attempt while staying beside the register.
- [ ] Confirm money changes once from `$0` to `$250` and the HUD reports `Robbery complete! +$250`.
- [ ] Confirm the register counts down a 20-second cooldown and cannot be robbed during it.
- [ ] After cooldown, confirm **READY** and the prompt return.
- [ ] Confirm wanted remains at zero; wanted and police response intentionally begin in Milestone 4.
- [ ] Reset the character and confirm the normal spawn and HUD still work.
- [ ] Confirm Studio Output has no red client or server errors.

## Two-client test on one laptop

Use Studio's **Test** tab, choose **Server & Clients**, set the player count to `2`, and start the test. Studio opens one server session and two client windows on the same laptop.

- [ ] Both clients have independent money and activity HUD values.
- [ ] Player 1 starts the robbery.
- [ ] Player 2 cannot start the same register while Player 1 is active.
- [ ] If Player 1 cancels, the register becomes available again and Player 2 can start it.
- [ ] If Player 1 succeeds, only Player 1 receives `$250`.
- [ ] Neither player can start another robbery during the shared cooldown.
- [ ] After cooldown, either nearby player can start the next robbery.
- [ ] The driver/passenger vehicle test still works for both clients.
- [ ] Ending the session produces no client or server script errors.

Milestone 3 passes when both lists work. Record any unexpected behavior before proceeding to wanted level and police pursuit.
