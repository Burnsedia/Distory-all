# Damage System — System Design Document

**Scope:** How typed damage, resistances, health, and death are handled.
**Reference:** GDD §6, §7. Code: `ECS/damage/` (component-based, no inheritance).
**Status:** `[SHIPPED]`.

---

## 1. Design intent

Damage is a **Node component**, not an inheritance hierarchy. Anything that can
take damage just has a child node named `DamageSystem`. Weapons, the wave
system, and splash damage all talk to it through the same `apply` API — so new
damage sources (lasers, mines, crew actions) need no extra plumbing.

```gdscript
DamageSystem.apply(node, DamageInstance.new(type, amount))
```

---

## 2. The component

`DamageSystem` (`class_name DamageSystem`, `extends Node`), attached as child
`DamageSystem`. Fields on the component:

| Field | Meaning |
|---|---|
| `max_health` | Starting + maximum health (default `100.0`) |
| `resistances` | Optional `Resistances` resource (null = no resistances) |
| `mineral_reward` | Minerals paid when the entity dies (GDD §6 table) |
| `death_faction` | Bookkeeping tag: `"enemy"`, `"enemy_station"`, `"player"`, `"player_station"`, `"core"`, or `""` |

Internal state: `health` (float), `dead` (bool). Reset in `_ready()`.

### Signals

| Signal | Emitted when |
|---|---|
| `damaged(instance, final_amount)` | Any damage applied (post-resistance) |
| `health_changed(current, max)` | Health changes (used by HUD/health bars) |
| `healed(amount)` | `heal()` restores health |
| `died` | Entity dies (emitted exactly once) |

The `died` signal triggers `_report_death()`, which emits
`Events.entity_died(self)` so `GameState` can do death bookkeeping (see §5).

---

## 3. Applying damage

### 3.1 `take_damage(instance)`

```
if dead: return 0
amount = instance.amount
if resistances: amount = resistances.apply(amount, type)   # apply per-type fraction
amount = max(amount, 0)
health -= amount
emit damaged, health_changed
if health <= 0 and not dead:
    dead = true; health = 0
    emit health_changed, died                              # die exactly once
return amount
```

### 3.2 `take_damage_raw(amount)`

Untyped damage that **bypasses resistances** (true damage). Useful for
finishing blows or effects that shouldn't be mitigated.

### 3.3 `heal(amount)`

`health = min(health + amount, max_health)`. No-op when dead. Emits `healed`.

### 3.4 `die()`

Immediate kill; emits `died` exactly once (guards against double-death).

---

## 4. Static helpers

```gdscript
DamageSystem.find_in(node)   # -> DamageSystem child, or null
DamageSystem.apply(node, instance)  # -> final amount, or 0 if undamaged
```

`apply` is the entry point weapons and the wave system use. It returns the
post-resistance amount so callers can report exact values.

---

## 5. `DamageInstance`

`class_name DamageInstance`, `extends Resource`:

```gdscript
DamageInstance.new(type: DamageType, amount: float)
```

A single packet of damage = a `DamageType` + an amount. Passed to `apply`/`take_damage`.

---

## 6. Damage types

`DamageTypes` (`extends RefCounted`) is a static registry:

| Type | Constant | File |
|---|---|---|
| Kinetic | `KINETIC` | `types/kinetic.tres` |
| Energy | `ENERGY` | `types/energy.tres` |
| Heat | `HEAT` | `types/heat.tres` |
| Radiation | `RADIATION` | `types/radiation.tres` |

`DamageType` (`class_name`, `extends Resource`) defines `id` (StringName),
`display_name`, `color`. Instances live under `ECS/damage/types/` and are
referenced by `DamageInstance`, `Resistances`, and every weapon.

---

## 7. Resistances

`Resistances` (`class_name`, `extends Resource`) maps damage-type ids to
reduction fractions in `0..1`:

- `0.0` = full damage
- `1.0` = immune

Example values dict: `{ "kinetic": 0.5, "energy": 0.1 }`.

Per-ship resistance resources exist for the shipped units (`player.tres`,
`cruiser.tres`, `drone.tres`, `station.tres`, `striker.tres`, `core.tres`).

---

## 8. Death bookkeeping in `GameState`

`GameState._on_entity_died(system)` reads `system.death_faction`:

- `"enemy"` / `"enemy_station"` → decrement enemy counts, award minerals,
  increment wave/shipyard progress.
- `"core"` → trigger sector loss / game over.
- `"player"` → player-ship death path.

This is the single choke point that ties damage → economy → win/lose.

---

## 9. Open questions

- Resistances are `Resource`s with no authored `apply` body visible here —
  confirm it correctly applies the fraction and clamps to `0..1`.
- Should "true damage" (`take_damage_raw`) ever hit `core`/shipyard, or always
  respect resistances?
- Should `mineral_reward` scale with wave/kill-value so late waves pay more?
