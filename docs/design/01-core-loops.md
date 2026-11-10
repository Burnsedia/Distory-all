# Core Loops — Game Design Document

**Scope:** The recurring gameplay loops that drive player attention.
**Reference:** GDD §3, §1, §12 (Roadmap).
**Status:** `[SHIPPED]` battle loop · `[M2]` campaign loop.

---

## 1. Design intent

Sector Defense is built on **nested loops**. The short battle loop keeps the
player engaged minute to minute; the long campaign loop gives those battles
weight by making outcomes persist. Both loops feed a single resource —
**minerals** — which ties management to combat.

Design pillars that the loops must serve (GDD §1):
- **Power fantasy** — 6DOF flight backed by wingmen and towers.
- **Commander fantasy** — map + overlay decisions win sectors, not just aim.
- **Stakes that persist** — losses hurt.
- **Escalation clarity** — players always know what happens next.

---

## 2. The four nested layers

| Layer | Type | Milestone | What the player does |
|---|---|---|---|
| 1 — Overworld | mini-4X | `[M2]` | Explore, expand, exploit, exterminate |
| 2 — Battle | mini-RTS | `[M1]` | Pause, place towers, order squadrons, produce |
| 3 — Tower Defense | TD | `[SHIPPED]` | Defend the Sector Core from waves |
| 4 — Wing Commander | cockpit combat | `[M0]` | Fly, command wingmen |

Layers are **state machines on a timeline**: Overworld → Battle → (win/lose) →
Overworld. Tower Defense and Wing Commander are the two *modes* a Battle can
take.

---

## 3. Campaign loop (`[M2]`)

```
Overworld
  │ collect income (minerals/minute from owned sectors)
  ▼
build / upgrade fleets & sectors
  ▼
move fleets along travel lanes
  ▼
a fleet enters a hostile sector  ──▶  BATTLE
  │                                          │
  ├── win  ── claim / upgrade the sector ──┐  │
  └── lose ── survivors retreat to a sector ┘  │
                                              ▼
                              march on the enemy home sector
                                              │
                                              └── destroy it ──▶ CAMPAIGN WON
```

**Win condition:** destroy the enemy home sector.
**Lose condition:** lose your own home sector.

Key behaviors (GDD §1):
- Pausable real-time map: ~12 sectors + travel lanes, 2 factions, fog of war.
- Explore: fleets entering unknown sectors reveal them.
- Expand: claim neutral sectors; upgrade shipyard / tower battery / extractor.
- Exploit: each owned sector pays minerals/minute into the faction treasury.
- Exterminate: fleets move in real time; entering a hostile sector starts a battle.
- Enemy campaign AI mirrors the player: builds fleets, probes the weakest sector.

---

## 4. Battle loop (`[SHIPPED]` + `[M0]`/`[M1]`)

```
Deploy with your fleet
  ▼
fight waves (escalating compositions)
  ▼
command wingmen (FSM: FORMATION → ATTACK → DEFEND → RTB)
  ▼
earn minerals (kills + wave-clear bonuses)
  ▼
[M1] pause overlay: build towers · order squadrons · produce units at carrier
  ▼
push the enemy ring
  ▼
destroy all 10 shipyards  ──▶  sector won
        (or your core dies ──▶ sector lost; surviving units retreat)
```

Escalation clarity is delivered by **wave banners**, visible **sector income**,
and clear **objectives** (destroy all shipyards).

### 4.1 Wave economy (the short-term micro-loop)

Each wave costs the player resources to clear and pays them back:
- Clearing a wave grants a `100 × wave` mineral bonus.
- Kills grant `mineral_reward` per entity (GDD §6 table).
- The battle loop therefore rewards *efficient, aggressive play*.

---

## 5. The unifying resource: minerals

Minerals appear in every loop and must never feel disconnected:

| Loop | Earned by | Spent on |
|---|---|---|
| Battle | kills, wave-clear bonuses | towers, wingmen commands |
| Campaign (M2) | sector income/minute | fleets, sector upgrades |
| Economy (M2) | treasury | **upkeep (wages)** or **offense (towers/units)** |

The **two-way spend** (GDD §8.1) — upkeep vs. offense — is the core strategic
tension: spending on wages keeps morale high but leaves you weaker today;
spending on offense makes you stronger now but risks mutiny later.

---

## 6. Feedback loops and risk

- **Victory snowball** (see `systems/04-morale-system`): winning → higher morale
  → fight better → win more.
- **Defeat spiral**: losing → lower morale → crews defect/bribe → lose more.
- The design must make these *visible and reversible* — a struggling faction
  should be able to claw back with a string of wins.

---

## 7. Open questions

- Are wave-clear bonuses scaling fast enough to stay ahead of inflation as
  shipyard costs grow (M2 upgrades)?
- Should the campaign loop let you *skip* a battle (retreat deliberately) to
  preserve a fleet?
