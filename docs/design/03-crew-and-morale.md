# Crew & Morale System — Game Design Document

**Scope:** The stat layers every manned crew has, and how morale ties combat to
management.
**Reference:** GDD §5.1, §8.1.
**Status:** `[M0]`.

---

## 1. Design intent

Every manned crew (fighter pilot + capital crew) has three stat layers. The
whole point of the system is that **morale is the bridge between the management
sim and combat** — bad payroll shows up as lost battles.

```
EVENTS (victory / defeat, pay, casualties, out-numbered)
  |  (filtered & personalized by PERSONALITY)
  v
MORALE  -->  combat stats  +  defection / bribe / flee risk
```

---

## 2. The three stat layers

### 2.1 Skills — combat performance only
- **Piloting** — maneuver, evasion.
- **Gunnery** — accuracy, damage output.
- **Engineering** — hull retention / survivability.

Skills are *earned/grown*, not morale-driven.

### 2.2 Morale — the umbrella state (0–100)
Morale = loyalty + confidence + will to fight. It is driven by events and
filtered by personality. Consequences of low morale:
- crews **defect** (GDD §8.2),
- crews **accept bribes** more readily (GDD §8.2),
- crews **flee** when damaged,
- crews **fight poorly** (global stat penalty).

### 2.3 Personality — traits
Traits (Loyal / Greedy / Brave / Cowardly — see `02-factions-and-units`) do two
things:
1. **Filter events** — decide how much each event moves morale.
2. **Grant conditional boosts** — improve a skill under the right condition.

---

## 3. Events move morale

- **Victories** (per battle) raise morale.
- **Defeats and heavy casualties** lower morale.
- **Momentum snowball**: win → higher morale → fight better → win more;
  lose → lower morale → crews defect/bribe → lose more.
- A struggling faction can recover by stringing together wins.

---

## 4. Personality filters events

| Trait | Under underpaying | Under combat stress |
|---|---|---|
| **Loyal** | barely drops | steady |
| **Greedy** | plummets | soars on bounties |
| **Brave** | — | morale *rises* when out-numbered / low |
| **Cowardly** | — | collapses when damaged |

---

## 5. Personality grants conditional stats

| Trait | Conditional boost |
|---|---|
| **Brave** | +Piloting when out-numbered / low morale |
| **Greedy** | +Gunnery when bounty is high |
| **Loyal** | +Engineering retention |
| **Cowardly** | −Piloting/dodge when morale is low |

---

## 6. Morale affects stats globally

High morale → confidence bonus across all skills. Low morale → penalty. This
closes the loop:

```
morale → effective skills → who wins the fight → next morale
```

---

## 7. Open questions

- Is morale a single 0–100 axis, or should loyalty, confidence, and will be
  tracked separately and combined?
- Should crew morale decay in *peacetime* (between campaigns) to pressure the
  economy even when not fighting?
