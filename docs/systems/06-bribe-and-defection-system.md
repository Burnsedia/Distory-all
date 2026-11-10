# Bribe War & Defection System — System Design Document

**Scope:** Two-sided mid-battle bribery and over-map defection.
**Reference:** GDD §8.2. Design: `design/04-economy-and-loyalty` §4.
**Status:** `[M0]` bribe war · `[M1]` over-map defection. Issue #28.

---

## 1. Design intent

The **bribe war** is a two-sided economy layer played *inside* a battle: spend
minerals to flip an enemy crew to your side; the enemy flips yours back. The
flipped crew takes their ship with them and rejoins your roster. This turns the
battle economy (`05-economy-system`) into a psychological contest
(`04-morale-system`).

---

## 2. Bribe war (in battle)

### 2.1 Requirements recap

Success scales with:
1. target's current **morale** (lower = easier),
2. their **personality** (Greedy = easiest, Cowardly next),
3. the **size of your offer**.

### 2.2 Cost model

Two candidate designs (`design/04` §6 open question):
- **Fixed cost per unit type:** flip a fighter = 300, cruiser = 800 minerals.
- **Negotiation:** player names an amount; higher offers raise success chance.

Recommended: **fixed base cost × offer multiplier** — base cost scales with
unit tier, and the player can overpay to boost success.

### 2.3 Success math

```gdscript
func bribe_success_chance(crew, offer, self_minerals):
    base = unit_tier_cost(crew)                     # fighter/cruiser/bomber
    morale_factor = 1.0 - crew.morale / 100.0        # 0..1, lower morale -> higher
    personality_factor = Personality.bribe_index(crew.personality)  # Greedy high, Loyal low
    overpay_factor = min(2.0, offer / base)          # overpaying helps, clamped
    return clamp(base * morale_factor * personality_factor * overpay_factor, 0.0, 1.0)
```

### 2.4 Two-sided resolution

- Player spends minerals → attempt flip. On success: crew flips to `player`,
  ship rejoins player roster.
- Enemy AI spends minerals → attempt flip of a player crew. On success: crew
  flips to `enemy`.
- Both sides consume minerals each round (a resource war).

### 2.5 Ownership & faction flip

On success the crew's `owner`/`loyalty` changes AND its `faction` flips
(so collision masks update — see `03-weapon-system` §5). The weapon mask must
follow the new owner, or the flipped ship friendly-fires. Coordinate with
`03-weapon-system` to flip weapon `faction` on successful bribe.

---

## 3. Over-map defection (`[M1]`)

A crew whose morale stays low (sustained underpaying) may **defect** and leave
your fleet — usually after a **warning grace period**.

### 3.1 Triggers

- Morale below `LOW` threshold.
- Sustained over N pay cycles (not a one-off dip).
- Personality-modulated (Greedy/Loyal defection thresholds differ).

### 3.2 Grace period

```gdscript
func defection_check(crew, cycles_below_low):
    if crew.morale >= LOW_THRESHOLD:
        reset grace period; return
    grace_cycles += 1
    if grace_cycles >= DEFECT_GRACE_CYCLES:   # e.g. 2-3 cycles
        crew_defects(crew)
```

The grace period gives the player a chance to fix pay before losing the crew.

### 3.3 Defection resolution

- Crew removed from roster.
- If on a capital ship, that crew slot goes empty (reduced ship capability).
- Fleet composition in the M2 fleet system updates.

---

## 4. Drones

Drones have **no crew** (GDD §8.2): immune to both bribery and defection. The
bribe UI must skip any unit with no `owner`/loyalty axis.

---

## 5. Integration points

| System | Seam |
|---|---|
| `04-morale-system` | reads `crew.morale`, `personality` for success & triggers |
| `05-economy-system` | minerals spent on offers; returns flip value |
| roster (`02-factions-and-units`) | crew reassignment on flip/defection |
| fleet (`M2`) | composition update after defection |

---

## 6. Open questions

- Can the enemy bribe *your* crews, or only defect on their own morale?
- Is there a bribe cooldown so the war can't be spammed each frame?
- Should defection be fully irreversible, or refundable if fixed fast enough?
