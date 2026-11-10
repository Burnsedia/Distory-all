# Sector Defense — Refactor & Feel Plan (Best Godot Practices)

Status: **Plan — not implemented.** Repo: `Distory-all` (Godot 4.7). GDD + 12 docs in `docs/`.
Smoke test (`res://test/smoke_launcher.tscn`) is GREEN (29 checks) but artificial — it
does not prove real combat (firing a weapon that actually hits and kills).

---

## 0. Guiding principle

The game passes isolated tests but does not feel shippable: flight is floaty/laggy,
firing/hits give no feedback, UI snaps ("clicky"), and enemy AI picks targets with
`randi()%3`. Goal: a clean refactor across the board + improve four feel dimensions
(flight/response, combat feedback, clicky UI, enemy AI).

Core architecture idea (from user): agent nodes request from services; systems interact
through the Events bus → emergent behavior. Refined to fit Godot's idioms (see §2)
rather than fighting them.

---

## 1. The refactor has two halves

- **Clean foundation** (Phases 0–1): split the `GameState` god-object, fix input, remove
  dead code, apply Godot idioms.
- **Feel pass** (Phases 2–5): flight/response, combat feedback, enemy AI, UI polish.

Smoke test is the guardrail for every phase — must stay green, and must be extended to
prove real combat.

---

## 2. Godot best-practice rules that shape the design

1. **Autoloads = only what truly needs global access.** Godot docs warn against using
   autoloads to "solve a design problem"; they are always in memory and a `_process`
   costs every frame. **Only 3 autoloads:** `Events`, `Global`, `Spawner`. All other
   managers are scene-instantiated singletons, not autoloads.
2. **Godot's idiomatic DI = `@export` node injection + signals**, not a custom Context
   container. A Context adds indirection and hides coupling. Use typed
   `@export var targeter: Targeting` (editor-dragged) + signals for runtime coupling.
3. **Prefer native signals over a custom Events bus.** Native signals are already the
   decoupling mechanism; the `Events` bus is reserved for cross-system broadcasts only.
4. **Nodes stay small and single-responsibility** (this is how emergence works: simple
   nodes + signals = complex global behavior). No god objects.
5. **Physics discipline:** `_physics_process` for movement/steering (not `_process`),
   `CharacterBody3D` for actors, `move_and_slide`/`move_and_collide` correctly, bullets
   as `Area3D`.
6. **Data-driven with `Resource`:** `WeaponDef`, `Personality`, etc. as `Resource`
   subclasses with `@export` — tunable in inspector, no magic numbers.
7. **Headless testing** (existing smoke test) — keep it; add typed signals + `class_name`.

---

## 3. Manager singletons vs. nodes that work together

- **Nodes = agents.** Each ship/weapon/NPC node makes local decisions using steering +
  personality + morale. It does NOT get pushed around; it **requests** from services:
  - `Targeting.request_target(ship)` → who do I fire at?
  - `Spawner.spawn_projectile(...)` → give me a missile
  - `Steering.steer(ship, goal)` → move toward that vector
  - `Economy.can_afford(cost)` → can I afford this upgrade?
- **Services = state + stateless-ish services.** They hold global state and answer
  requests; they do NOT dictate what nodes do.
- **`Events` bus = where systems work together.** Economy/Fleet/Wave/GameFlow coordinate
  via events, not direct calls. Loose coupling = emergence.
- **Emergence source:** simple per-node rules + feedback loops through the bus (low
  morale → node fights aggressively or flees/takes bribe → economy loses unit → Fleet
  recomposes → Wave sends bigger wave → surviving nodes steer around the threat). Nothing
  scripts this globally.

### Autoloads (only these 3)
| Singleton | Owns |
|---|---|
| `Events` | typed event bus (cross-system broadcasts) |
| `Global` | slim shared pointers (`player`, `maintower`) + `BULLET_MAX` |
| `Spawner` | pooled spawning — projectiles + ships/stations/objects (world) |

### Scene-instantiated singletons (NOT autoloaded)
| Singleton | Owns |
|---|---|
| `WeaponSystem` | fire control for weapon nodes (player AND AI) |
| `Targeting` | target acquisition, valid targets, priority |
| `FleetManager` | fleets, lanes, composition, persistence |
| `EconomyManager` | minerals, award/spend |
| `WaveDirector` | wave cycle, spawn queue |
| `BuildManager` | tower build/ghost/placement |
| `GameFlowManager` | start/restart/game over/menu |

---

## 4. Systems in detail

### 4.1 Spawner (autoload — facade over pooling)
Facade over object-pooling arrays: `spawn_projectile(kind, transform, cfg)`,
`spawn_unit(kind, pos)`, `release(obj)`, `despawn_all()`. Projectiles pre-warmed to
`BULLET_MAX`; ships/stations pool between waves. World builders (`SectorBuilder`,
`WorldBuilder`) build the map via `Spawner.spawn_unit(...)`. Replaces manual
`instantiate()`/`queue_free()` that currently churns allocation.

### 4.2 Weapon nodes (modular, tree-layered)
`Weapon` is a composable `Area3D` with layered children: `Muzzle` (spawn transform),
`AudioStreamPlayer3D`, `MuzzleFlash` (VFX). Attach only what each weapon needs; reuse as
archetypes. Ship nodes declare mounts; the weapon node lives on the mount. VFX/audio/
muzzle are siblings under `Weapon` so visuals and behavior stay decoupled.

### 4.3 WeaponSystem (scene singleton)
Drives fire control for weapon nodes: cooldowns, acquisition (via `Targeting`),
vector-steering lead-aim, firing through `Spawner`. Player-driven (input supplies target
+ fire intent) OR AI-driven (steering supplies target + timing). Same node + same
spawning system, different driving logic. Centralizes combat feedback (Phase 3):
muzzle/sound/recoil fire from here, consistent across every weapon.

### 4.4 Targeting (scene singleton)
Acquisition, valid-target filtering, priority. Every weapon node and NPC consults it.

### 4.5 NPC steering + AI (uses vector steering algorithms)
Steering family: seek / arrive / separate / avoid / wander. Movement AND combat AI built
on it. Same steering math powers the `WeaponSystem` lead-aim (one vector library).
Replaces `randi()%3` random targeting with real pursuit, keep-range, retreat-when-low.

### 4.6 FleetManager / Economy / Wave / Build / GameFlow
Coordinate through the `Events` bus (not direct calls) so they stay decoupled and emergent
behavior can arise. `Economy` constrains `Spawner` (can't spawn what you can't afford);
`WaveDirector` drives escalating waves; `FleetManager` handles persistence between
sectors; `BuildManager` + `GameFlowManager` handle placement and lifecycle.

### 4.7 Builders (constructor-injected services)
`ShipBuilder`, `WaveBuilder`, `WorldBuilder`, `WeaponBuilder` — build ships/waves/worlds/
weapons from `Resource` definitions, so nothing is hand-wired in scenes.

### 4.8 Morale (ties management sim to combat — the core loop)
Morale + personality drive whether a node holds / presses / flees / defects. This is the
feedback that makes the economy actually bite in combat. See `docs/systems/04-morale-system.md`.

---

## 5. Work order

**Phase 0 — Input & naming cleanup** (small, high value)
- Fix `project.godot` input: the `thruttle-up` typo (vs `throttle_up`), missing keyboard
  bindings for `boost` / `yaw_left` / `yaw_right`.
- Unify doubled pause handling (`ui_cancel` vs `menu`/`pause`) into one cancel path.
- Remove the redundancy where input is bound in `project.godot` AND re-bound at runtime in
  `GameState._ensure_input_bindings()` — one source of truth.
- Rename `Crusier` class + fix `thruttle` and other typos.

**Phase 1 — Architecture: 3 autoloads + split the god-object**
- Keep `Events`, `Global`; slim `Global` (drop `bulletCount`/`droneCount` → owned by
  `Spawner`).
- Add `Spawner` (autoload) + `Pooled` base.
- Split `GameState` into scene-instantiated singletons: `Economy`, `WaveDirector`,
  `GameFlow`, `Build` (and later `WeaponSystem`, `Targeting`, `FleetManager`).
- Sweep dead/legacy code: confirm `ECS/managers/*` (empty `weapon_manager` stub, etc.) is
  unused — remove or document; decide on half-built `ECS/ship-parts/`.

**Phase 2 — Flight & response feel**
- Tighten `lerp` smoothing in `Player.gd` (`input_response`, `acceleration`); add proper
  deadzones.
- Camera FOV triggers on turn rate, not just speed — reads as "committing to a maneuver."

**Phase 3 — Combat feedback**
- Add the missing sensory layer: muzzle flash, impact sparks, recoil, hit marker/feedback,
  screen shake, sound. Make firing/hits feel real.

**Phase 4 — Enemy AI**
- Real targeting (core/escort logic), cruiser keep-range strafe, retreat when low-HP — so
  the fight reads as a threat, not noise.

**Phase 5 — UI polish**
- Menu animations/easing, button hover/press states, consistent timing — fix clicky snap.

**Phase 6 — Verification**
- Keep smoke test green AND extend it to prove real combat: fire an actual weapon that
  hits and kills; assert nodes request from services, spawning goes through `Spawner`,
  steering drives AI, economy/fleet/wave interact through events, no code references the
  old statics (`Global.bulletCount`, etc.).

---

## 6. Open decisions

- Autoload breadth: confirmed — 3 max (`Events`, `Global`, `Spawner`); rest are scene
  singletons.
- Aim math: shared between `WeaponSystem` and NPC steering (one vector library) — yes.
- Targeting / Fleet as their own systems (not sub-systems of `WeaponSystem`/`WaveDirector`)
  — yes.
- Godot DI: `@export` node injection + native signals, NOT a custom Context container.
- Nodes request from services (services do not dictate behavior) — yes.
