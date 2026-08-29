# Milestone 6A+ Mega City Density Test

This build preserves the complete Milestone 5 gameplay loop and the validated center of Milestone 6A while quadrupling the generated city from 16 to 64 blocks.

## Scale and density

- [ ] Open `build/Milestone6A_MegaCity.rbxlx` and press **Play**.
- [ ] Confirm the original center city, Quick Stop, police station, jail, Gleep Glorp, and player spawn remain unchanged.
- [ ] Confirm the city now has nine east–west and nine north–south roads.
- [ ] Drive the new outer loop and confirm it connects around the entire map.
- [ ] Confirm the outer districts contain dense pairs of buildings on each block rather than large empty slabs.
- [ ] Find a mixture of storefronts, residential buildings, warehouses, hotels, markets, offices, and towers.
- [ ] Confirm the skyline varies in height and color instead of appearing as repeated identical boxes.
- [ ] Confirm the outer perimeter and boulevard edges have large, visible rows of trees.
- [ ] Confirm new streetlights, road markings, sidewalks, and guardrails continue through the outer districts.

## Vehicle and performance

- [ ] Drive Gleep Glorp through several inner and outer districts without sinking, falling, bouncing, or spinning.
- [ ] Confirm visual road and sidewalk layers do not flicker.
- [ ] Confirm trees and streetlights do not snag the vehicle.
- [ ] Confirm the game remains responsive while driving quickly across the city.
- [ ] Watch Studio's performance statistics and note any severe frame-rate, memory, or network spikes.

## Gameplay regression

- [ ] Rob the Quick Stop and confirm `$250` and wanted level 2.
- [ ] Confirm police dispatch, pursuit, last-seen searching, hidden countdown, star decay, and successful escape still work.
- [ ] After escaping, rob again and confirm a fresh police cruiser dispatches.
- [ ] Confirm arrest, confiscation, four-cell jail, and release still work.
- [ ] Confirm two clients retain independent HUD, wanted, money, police, and escape state.
- [ ] Studio Output has no red client or server errors.

If gameplay and laptop performance remain acceptable, commit this build before Milestone 6B road-aware police navigation.
