# Economy System — System Design Document

**Scope:** How minerals are awarded, spent, and tracked in battle, and how it
extends to the campaign treasury/upkeep.
**Reference:** GDD §8, §8.1. Code: `Globals/GameState.gd` (`minerals`).
**Status:** `[SHIPPED]` battle economy · `[M2]` treasury/upkeep.

---

## 1. Design intent

**Minerals** are the single currency of loyalty (GDD §8). In battle they pay for
towers, squadron commands, and units. On the overworld they flow into a
faction-wide **treasury** that pays wages (upkeep) or offense (towers/units).

---

## 2. Battle economy (shipped)

`GameState.minerals` (`int`) is the battle treasury. Signals:
`minerals_changed(value)` feeds the HUD.

### 2.1 Awarding

```gdscript
func award_minerals(amount: int) -> void
    if amount <= 0: return
    minerals += amount
    minerals_changed.emit(minerals)
```

Sources (GDD §6 table + battle loop):
- Kills: each dead entity awards `mineral_reward`.
- Wave clear: `100 × wave` bonus per cleared wave.

### 2.2 Spending

```gdscript
func spend_minerals(amount: int) -> bool
    if minerals < amount: return false
    minerals -= amount
    minerals_changed.emit(minerals)
    return true
```

Spend points in battle:
- Gun station: 1000
- Missile station: 1500
- Fighter wing: ~500
- Drone wing: ~250
- Bomber: ~1200
- Carrier repair: —

`spend_minerals` returns false on insufficient funds, so UIs can validate
before committing.

### 2.3 Starting state

`STARTING_MINERALS := 10000`. Reset to this in `start_game()`.

---

## 3. Wave economy ties in here

`_wave_composition(n)` escalates enemy counts with wave `n`
(drones `4+2n` cap 24; strikers from wave 3; cruisers from wave 5). Higher waves
cost more to clear but pay `100 × wave`, so the battle loop rewards aggressive,
efficient play (`design/01-core-loops` §4.1).

---

## 4. Campaign treasury & upkeep (`[M2]`)

Not yet implemented. Design (`GDD §8.1`, `design/04-economy-and-loyalty` §2–3):

- **Treasury** is faction-wide. `GameState.minerals` is the battle-local view;
  the overworld treasury is a separate persistent value.
- **Income:** owned sectors pay minerals/minute into the treasury.
- **Two-way spend:** wages (upkeep, keeps morale high) vs. offense (towers/units).
- **Wages loop** (`04-morale-system`): paying at/above each crew's
  `wage_requirement` keeps morale up; underpaying drains it.

### 4.1 Treasury state to add

```gdscript
# campaign (M2), over GameState for battle
var treasury: int
var income_per_minute: Dictionary  # sector_id -> minerals/min
var wage_cycle: float              # seconds between pay cycles
```

---

## 5. Economy ↔ morale wiring

The `minerals_changed` signal and wage events are the seam economy uses to drive
morale:

```
pay cycle elapsed -> Treasury.wage_cycle()
  -> for each crew: pay(wage)
       > wage_requirement:  MoraleChange(+, "pay")
       < wage_requirement:  MoraleChange(-, "pay")   (underpaid)
  -> morale system applies (filtered by personality)
```

---

## 6. Open questions

- Should `minerals` be a float internally to make tiny income deltas smooth?
- Is `spend_minerals` the right single choke point, or do we need per-source
  validators (e.g. "can't build tower while build_mode off")?
- Should wave-clear bonus `100 × wave` scale with the escalating composition
  so late waves stay worth clearing?
