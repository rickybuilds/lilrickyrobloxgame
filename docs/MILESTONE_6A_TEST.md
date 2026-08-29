# Milestone 6A Living City Expansion Test

Milestone 5 is the committed stable Phase 1 baseline. Milestone 6A changes generated map geometry and adds future navigation markers without changing police pursuit code or gameplay rules.

## City and road exploration

- [ ] Open `build/Milestone6A.rbxlx` and press **Play**.
- [ ] Confirm the original player spawn, Gleep Glorp, Quick Stop, Community Center, apartments, and police station remain in their familiar locations.
- [ ] Confirm the map now contains five east–west and five north–south streets.
- [ ] Drive around the connected outer road loop.
- [ ] Drive through multiple intersections and verify the roads have readable yellow center markings.
- [ ] Confirm boundary guardrails prevent casually driving off the city edge.
- [ ] Confirm roads, sidewalks, alleys, parking lots, and the pocket park do not flicker.
- [ ] Confirm Gleep Glorp does not sink, fall through, bounce, or begin spinning on any new visual surface.

## Buildings and city life

- [ ] Find signed buildings including **PIXEL PALACE**, **FIRE STATION**, **GLORP TOWER**, **CORNER CAFE**, **MOONLIGHT DINER**, **GLORP AUTO WORKS**, **MEGA MART**, **CITY LIBRARY**, and **SUNNY SCHOOL**.
- [ ] Confirm the new buildings have distinct colors, signs, windows, accent bands, and roof details.
- [ ] Confirm the inner streets now have dense rows of smaller shops such as **TOY BOX**, **BUBBLE TEA**, **PET SHOP**, **COMIC CLUB**, **BOOK NOOK**, and **CANDY SHOP**.
- [ ] Find **WEST PARKING** and drive through its open ground level.
- [ ] Confirm the garage contains pillars, parked cars, interior lights, opaque upper walls/decks, and enough ground-floor clearance for Gleep Glorp.
- [ ] Find both surface parking lots and their parked prop cars.
- [ ] Find the pocket park, benches, streetlights, alley dumpsters, and tree-lined city perimeter.
- [ ] Confirm parked prop cars and dumpsters behave as solid scenery while decorative trees and streetlights do not snag the vehicle.

## Alleys and escape gameplay

- [ ] Find and drive through the narrow asphalt alleys inside the four original central blocks.
- [ ] Confirm each alley connects back to a real street and does not end inside a building.
- [ ] Complete a Quick Stop robbery and allow police to establish contact.
- [ ] Break sight behind a large building, inside West Parking, or around an alley dumpster.
- [ ] Confirm the Milestone 5 **HIDDEN** countdown still starts only after police lose sight.
- [ ] Confirm being seen again resets the countdown.
- [ ] Remain hidden until both wanted stars clear and confirm the `$250` reward is secured.
- [ ] After fully escaping, rob the Quick Stop again and confirm a fresh cruiser dispatches from the police station.
- [ ] During an active police search, commit another robbery and confirm the existing unit redirects to the new crime location.
- [ ] Police vehicle routing is still the Milestone 5 direct-steering behavior; road-node routing is intentionally reserved for Milestone 6B.

## Regression and multiplayer

- [ ] Complete an arrest and confirm the four-cell jail and release behavior still work.
- [ ] Confirm lobby doors still show **ENTER** outside and **EXIT** inside.
- [ ] Confirm Gleep Glorp driver, passenger, exit, park, handbrake, speedometer, and reset controls still work.
- [ ] In a two-client test, confirm money, wanted, police state, and escape countdowns remain independent.
- [ ] Studio Output has no red client or server errors.

If every item passes, commit Milestone 6A before beginning road-aware police navigation in Milestone 6B.
