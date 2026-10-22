# Sector Defense — Game Design Document

**Version:** 0.2 (Playable Vertical Slice)
**Engine:** Godot 4.x
**License:** AGPL-3.0

## 1. Overview

Sector Defense is an open-source **hybrid tower-defense / space-combat** game set in a
decaying Dyson swarm. You are the last guardian of your sector. Enemy shipyards ring
the sector and pour escalating waves at your **Sector Core**. You fly a fighter into
the swarm, earn salvage (minerals) from kills, and spend it on defense stations around
the core. Lose when the core dies; win by destroying every shipyard.

**Pillars**

- **Power fantasy** — 6DOF fighter flight backed by a ring of turrets you built.
- **Risk/reward** — diving the shipyard ring to kill wave sources puts you in the swarm.
- **Strategy** — tower types counter enemy types (kinetic vs drones, energy vs shields, missiles vs swarms).
- **Escalation clarity** — wave banners, escalating compositions, visible objectives.

## 2. Core Loop

1. Main menu → Deploy → sector scene.
2. Fly and fight; kills automatically grant minerals.
3. Open the build menu, pick a station, fly into position (ghost preview shows
   validity near the core), place it.
4. Survive escalating waves; win by destroying all 10 shipyards; lose if the
   Sector Core or your ship dies.
5. Victory/defeat screen → Retry or Main Menu.

## 3. Factions & Collision Layers

| Layer | Value | Contents |
|---|---|---|
| 1 | 1 | Player ship |
| 2 | 2 | Enemy ships |
| 3 | 4 | Player stations (core, towers) |
| 4 | 8 | Enemy stations (shipyards) |
| 5 | 16 | Asteroids (visual only) |
| 6 | 32 | Bullets/missiles |

Player bullets hit layers 2+4; enemy bullets hit layers 1+3. Faction safety is
enforced entirely by collision masks — a bullet can never hit its own side.

## 4. Damage System (issue #18)

Reusable, inheritance-free, built from Resource objects:

- **`DamageType`** (Resource) — `kinetic`, `energy`, `heat`, `radiation`
  (`.tres` files in `ECS/damage/types/`).
- **`DamageInstance`** (Resource) — a `DamageType` + an amount.
- **`Resistances`** (Resource) — per-type reduction map (0 = full damage, 1 = immune).
- **`DamageSystem`** (Node component, `ECS/damage/DamageSystem.tscn`) — attach as a
  child named `DamageSystem` to anything damageable. Exports `max_health`,
  `resistances`, `mineral_reward`, `death_faction`. Signals: `damaged`,
  `health_changed`, `healed`, `died`.

Death bookkeeping flows through `Events.entity_died(system)` → `GameState`.

Roles and resistances:

| Entity | HP | Kinetic | Energy | Heat | Rad | Reward |
|---|---|---|---|---|---|---|
| Drone | 100 | 25% | 10% | 20% | 0% | 50 |
| Striker | 120 | 10% | 30% | 0% | 0% | 100 |
| Cruiser | 800 | 15% | 50% | 30% | 10% | 300 |
| Shipyard | 3000 | 20% | 20% | 20% | 20% | 2000 |
| Gun/Missile station | 1500/1200 | 20% | 20% | 20% | 20% | — |
| Sector Core | 5000 | 10% | 10% | 10% | 10% | — |
| Player | 1000 | 20% | 40% | 30% | 30% | — |

## 5. Enemies

| Enemy | Behavior | Notes |
|---|---|---|
| Drone (Challenger) | Seeks target, strafes with a kinetic peashooter, rams at close range | Swarm filler; kamikaze impact 500 kinetic |
| Striker | Fast weaver, no guns, detonates on contact | Introduced wave 3; heat-vulnerable |
| Cruiser (Cursier) | Keeps 220–450 range, strafes, energy bolts | Tanky, shielded; introduced wave 5 |
| Shipyard | Static wave source on the sector ring | Primary objective |

Targeting: drones/cruisers prefer the player, occasionally the core; strikers prefer
the core. All enemies despawn (count as cleared) beyond 900 units from the sector
center so waves can never stall.

## 6. Player

- Freelancer-style flight: W/S pitch + throttle, A/D yaw, Q/E roll, Shift boost,
  Space fires the nose gun (kinetic, 25 damage).
- Chase camera trails behind the ship, looks ahead, widens FOV at speed (issue #10).
- 1000 HP with energy-biased shields. Death = sector lost.

## 7. Towers & Economy

- Start: **10,000 minerals**. Kills grant the rewards above; wave clears grant a
  `100 × wave` bonus.
- **Gun Station** (1000) — 4 kinetic turrets, ~75 combined DPS. General purpose.
- **Missile Station** (1500) — 2 pods firing homing heat missiles (150 splash,
  radius 45). Anti-swarm.
- Placement: within **260 units** of the core, at least 40 units away. Ghost preview
  is green when valid, red otherwise.

## 8. Wave Director (GameState)

- 10 shipyards ring the core at radius 500. Waves spawn from random living shipyards.
- Composition: `drones = min(4 + 2n, 24)`, `strikers = n - 2` (wave 3+),
  `cruisers = (n - 4) / 2` (wave 5+).
- First wave at 8s; after a clear, 12s intermission, then the next wave.
- Win: all shipyards destroyed. Lose: core or player dies.

## 9. UI

- **Main menu** — Deploy / Controls / Quit (keyboard + gamepad focus).
- **HUD** — minerals, wave, hostiles, shipyards; player + core HP bars; banner
  announcements; crosshair; build menu; pause menu; victory/defeat overlay with
  stats (waves survived, minerals held).

## 10. Input

| Action | Keyboard | Gamepad (Steam Deck) |
|---|---|---|
| Throttle / pitch | W / S | A / B buttons |
| Yaw | A / D | Right stick X |
| Roll | Q / E | Right stick? (bindable) |
| Fire | Space | RB |
| Boost | Shift | LB (bindable) |
| Build menu | B | View button |
| Select gun / missile | 1 / 2 | X / Y |
| Place station | Enter | A |
| Cancel / pause | Esc | Start / B |

## 11. Roadmap (tracked as GitHub issues)

- [x] #12 Port to Godot 4
- [x] #18 Damage System (Resources + component)
- [x] #10 Chase camera (base implementation)
- [ ] #23 Save game system
- [ ] #16 Overworld map — sector map, fleet system, basic 4X
- [ ] #19 Squadron control system — assign drone wings to targets
- [ ] #20 State machine refactor of the steering AI
- [ ] Shipyard defense turrets (risk on the ring)
- [ ] More towers: shield station, repair pad, laser lance

## 12. Testing

- `test/unit_tests.gd` (+ `unit_runner.tscn`) — damage-system unit tests.
  `godot --headless --path . res://test/unit_runner.tscn`
- `test/smoke_launcher.tscn` (+ `smoke_launcher.gd`, `smoke_core.gd`) — boots the
  real game scene and drives a full gameplay arc (wave → clear → tower → victory).
  `godot --headless --path . res://test/smoke_launcher.tscn`
