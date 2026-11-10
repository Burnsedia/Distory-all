# Weapon System — System Design Document

**Scope:** How `Weapon`, `Bullet`, and `Missile` fire, hit, and stay on-faction.
**Reference:** GDD §6. Code: `ECS/weapons/` (attached as `Weapon`).
**Status:** `[SHIPPED]`.

---

## 1. Design intent

A `Weapon` is an `Area3D` child named `Weapon` (muzzle points along `-Z`). It
configures and spawns a `Bullet`. All projectiles are **faction-tagged** so a
bullet can never hit its own side (GDD §6 — the `faction` safety).

The single cross-cutting constraint: **bullet count cap** (`Global.BULLET_MAX`)
protects performance against bullet spam.

---

## 2. `Weapon`

`class_name Weapon`, `extends Area3D`:

| Field | Meaning | Default |
|---|---|---|
| `damage` | Bullet damage | `10.0` |
| `damage_type` | `DamageType` | `KINETIC` |
| `bullet_speed` | Travel speed | `1600.0` |
| `faction` | `"player"` or `"enemy"` — sets hit mask | `&"player"` |

`_ready()` zeroes collision layer/mask and disables monitoring; monitoring is
only on while a bullet is in flight.

### `shoot()`

1. Guard: if `Global.bulletCount >= BULLET_MAX`, return (throttle).
2. Instantiate `Bullet.tscn`, add to `current_scene`.
3. Copy `global_transform` to the bullet.
4. `bullet.configure(damage, damage_type, faction, bullet_speed)`.
5. Play `$AudioStreamPlayer3D` if present.

`charged_shot()` is a stub for later secondary abilities.

---

## 3. `Bullet`

`class_name Bullet`, `extends Area3D`. Configured at spawn (or on first frame if
not configured). Fields: `speed`, `damage`, `damage_type`, `faction`, `lifetime`.

### Collision masks (the faction guard)

```gdscript
ENEMY_MASK := (1<<1) | (1<<3)   # player bullets -> enemy ships + enemy stations
PLAYER_MASK := (1<<0) | (1<<2)   # enemy bullets -> player ship + player stations
```

`configure()` sets `collision_mask = ENEMY_MASK if player else PLAYER_MASK`.

### Lifecycle

- `_ready()`: increments `Global.bulletCount`, spawns a `lifetime` timer.
- `_physics_process`: moves along `-Z` of its transform.
- `_on_bullet_body_entered`: decrements `bulletCount`, applies damage to the body
  (`DamageSystem.apply(...)`), queues self free.

---

## 4. `Missile`

`class_name Missile`, `extends Area3D`. Homing explosive projectile. Fields:
`speed`, `damage`, `damage_type`, `splash_radius`, `faction`, `lifetime`,
`turn_speed`.

- Defaults: `HEAT`, `splash_radius 45`, `turn_speed 3.0`.
- `set_target(node)` sets the homing target.
- `_physics_process`: slerp heading toward the target (or forward if no valid
  target), then move. Auto-explodes within `8.0` units of the target.
- Timed `explode()` after `lifetime` (fallback homing).

### Splash damage

`explode()`:

1. Guard `_exploded` (single fire).
2. Decrement `bulletCount`.
3. For each node in the opposing faction group (`enemies` for player missiles,
   `player` for enemy missiles): within `splash_radius`, apply
   `damage * (1 - 0.5 * d/splash_radius)` falloff.
4. **Special case:** player missiles also splash **enemy stations**
   (`enemy_stations` group) — this is how the bomber/missile can damage
   shipyards (GDD §2 objective).
5. Queue free.

---

## 5. Faction safety — the invariant

A bullet's collision mask is set by **faction**, not by who fired it. This means
bribed/hacked ships firing their weapons never friendly-fire their own (now)
side — the mask follows the weapon's `faction`, so a flipped crew's shots still
match the old target set until ownership logic elsewhere also updates.
(Design note: faction-swap ownership may need to also invert weapon masks — see
`bribe-and-defection-system`.)

---

## 6. Open questions

- Should `faction` live on the `Weapon` or be set per-shot? A bribed ship would
  need its weapons' mask to flip on ownership change.
- Is `BULLET_MAX = 2000` still the right cap on Steam Deck at 40 fps?
- Should splash falloff hit `core`/shipyard the same way for both factions?
