# Architecture — System Design Document

**Scope:** How the game is put together in Godot — globals, ECS, scenes, groups.
**Reference:** GDD §0, §6, §7. Code: `Globals/`, `ECS/`, `NPCs/`, `Player/`.
**Status:** `[SHIPPED]` foundation.

---

## 1. Project layout

```
docs/
ECS/            # reusable components + gameplay systems
  damage/       # DamageSystem, DamageType, DamageInstance, Resistances
  weapons/      # Weapon, Bullet, Missile
  managers/     # health/movement/weapon managers (legacy ECS)
  ship-parts/   # ship model parts (Core, Engines, etc.)
  VFX/
NPCs/
  Ships/        # Cursier (Cruiser), Drone, Striker
  Stations/     # DefenseStation, EnemyShipYard, MainTower, Turret, etc.
Player/         # Player (fighter), PlayerCamera
Globals/        # autoloads: Global, GameState, Events
plugins/        # Godot addons (analog UI, GitHub integration)
test/           # unit + smoke tests
```

---

## 2. Autoloads (singletons)

| Autoload | Responsibility |
|---|---|
| `Global` | Small shared state & counters (`player`, `maintower`, `droneCount`, `bulletCount`, `BULLET_MAX`). Safety clamp in `_process`. |
| `GameState` | The game **director**: wave cycle, economy, win/lose, tower placement. Emits signals (`minerals_changed`, `wave_changed`, `enemies_changed`, `shipyards_changed`, `game_over`). |
| `Events` | Global **event bus** so systems decouple (e.g. `entity_died`, `message`, `shoot`). |

**Rule of thumb:** `Global` holds counters; `GameState` holds rules; `Events`
carries broadcasts.

---

## 3. Damage is component-based, inheritance-free

`DamageSystem` is a **Node component** attached as a child named `DamageSystem`
to anything that can take damage. No inheritance required:

```gdscript
# apply typed damage
DamageSystem.apply(node, DamageInstance.new(type, amount))

# signals on the component
signal damaged, health_changed, healed, died
```

Death bookkeeping: `died` → `Events.entity_died(system)` → `GameState` matches on
`death_faction` (`"enemy"`, `"enemy_station"`, `"core"`, `"player"`).

---

## 4. Faction safety via collision masks

`Weapon.faction` and `Bullet.faction` are `StringName` (`"player"` / `"enemy"`).
Bullets set a **collision mask** so a bullet can never hit its own side
(`01-architecture` § — see `weapon-system`).

| Layer | Value | Contents |
|---|---|---|
| 1 | 1 | Player ship |
| 2 | 2 | Enemy ships |
| 3 | 4 | Player stations |
| 4 | 8 | Enemy stations |
| 5 | 16 | Asteroids (visual) |
| 6 | 32 | Bullets/missiles |

---

## 5. Groups for discovery

`GameState` and systems find entities by Godot groups: `player`, `enemies`,
`player_stations`, `enemy_stations`. This is how the missile splash, wave
tracking, and death bookkeeping find targets without hard references.

---

## 6. Milestone ownership

| Layer | Owning doc |
|---|---|
| Damage | `systems/02-damage-system` |
| Weapons | `systems/03-weapon-system` |
| Morale | `systems/04-morale-system` |
| Economy | `systems/05-economy-system` |
| Bribe/defection | `systems/06-bribe-and-defection-system` |
| Save | `systems/07-save-system` |

---

## 7. Open questions

- `Global` mixes *shared state* and *performance caps*. Should caps move to
  `GameState`?
- The `managers/` folder (`health_manager`, `movment_manager`, `weapon_manager`)
  predates the component-based `DamageSystem` — is it legacy or still in use?
