# Crew & Morale System — System Design Document

**Scope:** The data structures, FSM, and event pipeline that implement morale.
**Reference:** GDD §5.1, §8.1. Design: `design/03-crew-and-morale`.
**Status:** `[M0]` — not yet implemented (issue #26).

---

## 1. Design intent

Morale is the bridge between the management sim and combat: a crew whose morale
drops (from underpaying, losses, or enemy bribery) fights worse and is more
likely to defect. This doc covers the **data model**, the **FSM/event pipeline**,
and how morale feeds back into combat stats.

This system does not exist in code yet. The `DamageSystem` component
(`systems/02-damage-system`) is the natural home for morale callbacks
(`damaged`, `health_changed`, `died`), so morale can observe combat events
without those systems knowing about it.

---

## 2. Data model

### 2.1 Crew

`class_name Crew` (`extends Resource` or an `RefCounted`):

| Field | Type | Notes |
|---|---|---|
| `pilot_id` | int | roster key |
| `pilot_name` | String | display |
| `skills` | `CrewSkills` | piloting/gunnery/engineering |
| `morale` | float | 0..100 umbrella state |
| `personality` | Personality enum | Loyal/Greedy/Brave/Cowardly |
| `wage` | int | minerals/week |
| `wage_requirement` | int | personality-driven pay threshold |
| `loyalty` | float | 0..1 (for defection math) |
| `contract` | bool | mercenary = defection-capable |

### 2.2 CrewSkills

`class_name CrewSkills`: `piloting`, `gunnery`, `engineering` (each 0..100).
Skills **grow**; morale does not.

### 2.3 Personality

`class_name Personality` (enum + trait data):

| Trait | pay_requirement delta | bribe_index | conditional boost |
|---|---|---|---|
| Loyal | −30 | high (hard) | +Engineering retention |
| Greedy | +40 | easiest | +Gunnery when bounty high |
| Brave | 0 | medium | +Piloting when out-numbered/low |
| Cowardly | −10 | eager | −Piloting/dodge when morale low |

---

## 3. Effective skills

Morale is a global multiplier on skills:

```
effective_skill(base, morale) =
    base + conditional_boost(personality) + morale_bonus(morale)

morale_bonus(morale) =
    if morale >= 70:  +bonus
    if morale <= 30:  -penalty
    else:              0
```

The FSM/state writes `morale`; combat reads `effective_*` each frame. This is
the loop from `design/03`: `morale → effective skills → who wins → next morale`.

---

## 4. Morale FSM / state machine

The morale state is a small finite machine over the umbrella value:

```
STABLE ──(morale drops below low)──▶ LOW
LOW   ──(morale recovers above mid)──▶ STABLE
LOW   ──(loyalty/condition breached, sustained low)──▶ DEFECTING
```

Guard conditions trigger side effects (see §6): entering `LOW` arms the bribe
vulnerability; entering `DEFECTING` starts the warning grace period.

---

## 5. Event pipeline — the core of the system

The morale system observes events on the `Events` bus and applies `MoraleChange`
values. This is the pipeline to implement:

```
Events (on bus)
  ├── entity_died(system)        -> casualty event
  ├── wave_changed / game_over   -> victory/defeat
  └── (economy) wage_paid(...)   -> pay event

Events -> filter by PERSONALITY -> apply MoraleChange -> update morale
```

### 5.1 MoraleChange

`class_name MoraleChange`:

```gdscript
class_name MoraleChange
var amount: float
var source: StringName   # "victory" | "defeat" | "pay" | "casualty" | "bounty"
```

### 5.2 Personality filtering

Each source has a base weight per trait; the personality multiplies it:

| Source | Loyal | Greedy | Brave | Cowardly |
|---|---|---|---|---|
| victory | +10 | +12 | +15 | +6 |
| defeat | −12 | −18 | −10 | −22 |
| underpaid pay | −3 | −25 | −8 | −12 |
| paid well | +8 | +20 | +8 | +5 |
| bounty (greedy high) | 0 | +15 | 0 | 0 |
| out-numbered | 0 | 0 | +12 | −8 |
| damaged | 0 | 0 | +2 | −18 |

The filtered result is what `apply()` writes to `morale`. This is the exact
table from `design/03-crew-and-morale` §4.

---

## 6. Momentum snowball

Victories cause a **snowball** (GDD §5.1):

```
win -> morale up -> effective skills up -> win more -> morale higher
```

Implement with a per-faction `momentum` accumulator: each battle win adds to
momentum, each loss subtracts; momentum biases the morale change on the next
event (`morale_change *= 1 + momentum_scale`). Clamp momentum so a losing
faction can claw back.

---

## 7. Integration points

| Where | How |
|---|---|
| `Events.entity_died` | casualty event → morale delta (larger for capital crew losses) |
| `game_over(won)` | victory/defeat event → morale delta |
| `GameState.spend_minerals` / wage pay | pay event → morale delta filtered by wage_requirement |
| `bribe-and-defection-system` | bribe offers and defection both read current morale |
| combat read path | `effective_*` skills each frame from `morale` + personality |

Keep morale **decoupled**: systems only emit events on the bus; the morale
system subscribes. Combat reads skills; it doesn't call morale.

---

## 8. Open questions

- Is morale a single 0–100 axis, or split into loyalty/confidence/will?
- Should morale decay in peacetime to pressure the economy between campaigns?
- What morale threshold defines "LOW", "STABLE", "DEFECTING"?
