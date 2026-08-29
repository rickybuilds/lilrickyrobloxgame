# Phase 1 MVP Plan

## Product boundary

Phase 1 proves one small, complete loop:

> Drive to the store → rob the register → police respond → escape the search → wanted level clears → keep the reward.

The tone is playful and non-realistic. The MVP has no firearms, gore, drugs, or mature crime themes. Police arrest rather than kill players. Melee tools are deferred until after this loop is fun.

## Architecture

The project uses a lightweight service/controller architecture:

- **Server services** own money, wanted state, robbery validation, police decisions, arrests, and vehicles.
- **Client controllers** handle input, camera/UI presentation, and interaction prompts. Clients request actions but never decide rewards or results.
- **Shared configuration** contains tuning values and names used by both sides.
- **Remotes** are added only as a system needs them. Each server handler validates the player, distance, state, cooldown, and request rate.
- **Runtime world generation** creates the Phase 1 blockout without third-party models. We can later replace generated landmarks with hand-built Studio models while keeping the gameplay services.

Player attributes replicate display state such as `Money`, `WantedLevel`, and `RobberyStatus`. Only server modules write authoritative attributes. Persistent data will be added after the loop is stable; Milestone 1 state lasts for one server session.

## Target Roblox Studio hierarchy

```text
ReplicatedStorage
├── Shared
│   └── Config
│       └── GameConfig                 (ModuleScript)
└── Remotes                            (Folder; empty until needed)

ServerScriptService
├── Main                               (Script)
└── Services
    ├── EconomyService                 (ModuleScript)
    ├── PlayerStateService             (ModuleScript)
    ├── RobberyService                 (ModuleScript)
    ├── VehicleService                 (ModuleScript)
    └── WorldService                   (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    ├── Main                           (LocalScript)
    └── Controllers
        └── HudController              (ModuleScript)

Workspace                              (generated when Play starts)
└── GameWorld
    ├── Ground
    ├── Roads
    ├── CityBlocks
    ├── Landmarks
    │   ├── ConvenienceStore
    │   └── PoliceStation
    └── Spawns
        ├── PlayerSpawn
        ├── VehicleSpawn
        └── PoliceSpawns
```

Later milestones add the other named services and controllers only when they have a real responsibility. This avoids empty abstractions and makes the project easier for a young co-developer to follow.

## Generated versus manual work

### Generated now

- Roads, ground, sidewalks, blockout buildings, store shell, and police station
- Spawn points for players, the first car, and police response units
- Register placeholder and readable world signs
- HUD and server-owned session player state

### Manual Studio work eventually

- A polished city layout and original building art
- A good vehicle model with a chassis, wheels, seats, lights, and sounds
- Character animations for melee tools and arrests
- Original icons, UI art, vehicle sounds, sirens, and music with suitable licenses
- Navigation/path markers tuned to the final streets

For the first car, a simple chassis can be built from Parts in Studio or from our own scripted prototype. We should avoid random Toolbox vehicle kits because they can contain hidden scripts and often use incompatible/deprecated chassis code.

## Implementation milestones

### Milestone 1 — Playable foundation (stable)

Create the project skeleton, generated test city, server-owned player state, and HUD.

Test checklist:

- Spawn in the city.
- Identify the store, police station, and future vehicle pad.
- Confirm money `$0`, wanted `0`, and `Explore the city` appear.
- Confirm a two-player Studio test works without errors.

### Milestone 2 — One drivable car (stable)

Add one arcade car, server-controlled seat assignment, enter/exit interaction, acceleration, braking, steering, reverse, handbrake, health, and reset-if-stuck behavior.

Test checklist:

- Only a nearby player can enter.
- Driver input moves and steers the car; passenger seat does not control it.
- Exit places the character safely beside the car.
- Two players cannot claim the driver seat simultaneously.
- Vehicle behavior is acceptable in a two-player server.

### Milestone 3 — Store robbery and economy (stable)

Add a server-validated register prompt, robbery countdown, cancellation on leaving the area, payout, store cooldown, and HUD status.

Test checklist:

- A nearby player can start one robbery.
- Leaving early cancels it and gives no money.
- Staying completes it and awards money once.
- A second player cannot bypass the active/cooldown state.
- Remote spam or distant requests give no reward.

### Milestone 4 — Wanted level and basic police pursuit

Add wanted severity, one police response vehicle/NPC, sensible station/patrol spawning, target selection, vehicle pursuit, on-foot pursuit, and a basic arrest result.

Status: **Stable.** A separate 4P polish pass improves the police station and its indoor four-cell jail before Milestone 5.

Test checklist:

- Completing a robbery raises wanted level.
- Police begin at the station or a valid distant response point, never beside the player.
- Police chase the correct wanted player on foot and in a vehicle.
- Arrest clears wanted, removes a configured portion of unbanked robbery money, and briefly sends the player to jail.
- Multiple wanted players do not share or overwrite one another's state.

### Milestone 5 — Escape, wanted decay, and integrated loop

Add police sight/search state, escape timer, wanted decay, cleanup/return behavior, and final Phase 1 tuning.

Status: **Implemented; awaiting Roblox Studio runtime validation.**

Test checklist:

- The escape timer starts only after police genuinely lose sight/range.
- Being spotted again pauses or resets escape progress.
- Remaining unseen eventually clears wanted level and dismisses police.
- The successful robbery reward remains after escape.
- The full drive–rob–chase–escape loop works repeatedly in a two-player test.

## Security rules for every milestone

- The server calculates rewards, wanted changes, damage, arrests, ownership, and purchases.
- The server verifies interaction distance and current character state.
- The server owns shared cooldowns and uses one-way state transitions to prevent duplicate payouts.
- Client requests are rate-limited once remotes exist.
- DataStore persistence is isolated behind a player data service and tested separately before release.
