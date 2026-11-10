# Economy & Loyalty — Game Design Document

**Scope:** The mineral economy, wages, and the bribe war / defection system.
**Reference:** GDD §8, §8.1, §8.2.
**Status:** `[SHIPPED]` battle economy · `[M0]` bribe war · `[M1]` over-map defection · `[M2]` treasury/upkeep.

---

## 1. Design intent

Minerals are the single currency of loyalty. They are earned, then spent two
ways at once: **upkeep (wages)** to keep morale high, or **offense (towers/units)**
to be stronger today. Skimp on upkeep and your army becomes vulnerable.

---

## 2. Treasury & income (`[M2]`)

- The **treasury** is faction-wide. During a battle it is `GameState.minerals`.
- **Income:** owned sectors pay minerals/minute on the overworld; kills and
  wave clears pay in battle.
- **Starting minerals:** 10,000.

### 2.2 Costs

| Item | Cost | When |
|---|---|---|
| Gun station | 1000 | `[SHIPPED]` |
| Missile station | 1500 | `[SHIPPED]` |
| Fighter wing | ~500 | `[M1]` |
| Drone wing | ~250 | `[M1]` |
| Bomber | ~1200 | `[M1]` |
| Carrier repair | — | `[M1]` |
| Sector upgrades (extractor/shipyard/tower battery L1–3) | — | `[M2]` |

---

## 3. Wages & the morale/pay loop (`[M2]`)

- Every manned crew has a **wage**. Wages are paid from the treasury on a cycle.
- **Wages drive morale** (`03-crew-and-morale`): paying at/above a crew's
  pay-requirement keeps morale up; underpaying drains it.
- **Personality sets the requirement**: Greedy needs more, Loyal less.

The tension: same minerals either keep morale high (safe) or buy towers/units
(stronger now). The player is always choosing between strength today and
loyalty tomorrow.

---

## 4. Bribe war (mid-battle) & over-map defection

### 4.1 Bribe war — `[M0]`, in battle

During a battle you can spend minerals to flip an enemy crew to your side — and
the enemy can flip yours back.

**Success scales with:**
1. the target's current **morale** (lower = easier),
2. their **personality** (Greedy = easiest, Cowardly next),
3. the **size of your offer**.

A flipped crew takes their ship with them and rejoins your roster. Drones are
immune (no crew).

### 4.2 Over-map defection — `[M1]`

A crew whose morale stays low (sustained underpaying) may **defect** and leave
your fleet — usually after a short **warning grace period** so you can fix the
pay. This is what makes upkeep matter between battles.

---

## 5. The loyalty loop

```
Treasury
  ├── wages  → morale  → loyalty → defect/bribe risk
  └── offense → towers/units → military strength
       ▲                              │
       └────── enemy bribes your crews ──┘
```

The player manages a constant tightrope: grow strong enough to win, but pay
enough to not lose your army from within.

---

## 6. Open questions

- Should bribes be a *negotiation* (player names an amount) or a **fixed cost
  per unit type** (flip a cruiser = 800 minerals)?
- Can the enemy bribe *your* crews, or only defect-prone ones defecting on
  their own?
