# Sector Defense — Game Design Document

**Version:** 0.3 — four-layer vision: **Wing Commander × Tower Defense × mini-RTS × mini-4X**
**Engine:** Godot 4.x
**License:** AGPL-3.0
**Platform:** PC + Steam Deck (not mobile — see §11)

Status markers: `[SHIPPED]` in the game · `[M0]`/`[M1]`/`[M2]`/`[M3]` planned milestones (§12).

## 1. Overview

You are a **wing commander** in a decaying Dyson swarm, leading a remnant faction
against a rival for control of a cluster of sectors. You fly your fighter into
every battle, command a wing of AI wingmen, build the defenses — and between
battles, run the war on a sector map.

The game is four layers, nested:

1. **Overworld (mini-4X)** — the campaign spine: explore, expand, exploit, exterminate.
2. **Battle (mini-RTS)** — pausable command overlay: towers, squadron orders, unit production.
3. **Tower Defense** — towers defend your Sector Core from escalating waves.
4. **Wing Commander** — cockpit combat, wingmen, the feel layer.

Reference cocktail: Wing Commander (combat + wingmen) × Battlezone / Sins of a
Solar Empire (pilot ↔ command) × Kingdom Rush (towers) × Stellaris-lite (map).

**Pillars**

- **Power fantasy** — 6DOF fighter flight backed by wingmen and towers you command.
- **Commander fantasy** — your decisions on the map and in the overlay win sectors, not just your aim.
- **Stakes that persist** — sectors, fleets and towers carry between battles; losses hurt.
- **Escalation clarity** — wave banners, sector income, visible objectives.

## 2. The Four Layers

### Layer 1 — Overworld (mini-4X) `[M2]` (issue #16)

- **Pausable real-time** sector map: ~12 sector nodes + travel lanes, **2 factions**, fog of war.
- **Explore** — fleets entering unknown sectors reveal them.
- **Expand** — claim neutral sectors; upgrade owned ones (shipyard level, tower battery, extractor).
- **Exploit** — each owned sector pays minerals per minute into a faction treasury.
- **Exterminate** — fleets move along lanes in real time; a fleet entering a hostile
  sector starts a battle. Destroy the enemy **home sector** to win the campaign;
  lose yours and it's over.
- **Enemy campaign AI** mirrors the player: builds fleets, probes your weakest sector.
- The map pauses when you issue orders; time flows otherwise.

### Layer 2 — Battle (mini-RTS) `[M1]`

- Fleet units from the overworld become friendly ships in the 3D battle; the sector's
  **persistent** towers and garrison (built in earlier defenses) are already present.
- The enemy sector has shipyards and escalating waves, as today `[SHIPPED]`.
- **Command overlay** `[M1]`: hold a button → game pauses → you can place towers,
  order squadrons ("move here / attack that"), and **produce units** at your carrier
  (fighter wings, drone wings) using the treasury.
- **Carrier** `[M1]`: a mobile base in battle. Lose it and you lose production;
  keep it safe.
- Battle ends when the enemy shipyards fall (**sector won**) or your core dies
  (**sector lost** — surviving fleet units retreat to a friendly sector).

### Layer 3 — Tower Defense `[SHIPPED]` (extended `[M3]`)

- Towers defend the Sector Core from waves. Gun + Missile stations ship now;
  a Shield station arrives in M3.
- `[M2]` Towers persist per sector and repair between battles — defending a sector
  is an investment, not a one-off.

### Layer 4 — Wing Commander `[M0]` (issues #10, #19, #20)

- You always fly. **3 AI wingmen** fly with you.
- **Wingman command menu** `[M0]`: Attack my target · Form on my wing ·
  Break and attack · Defend the core · Return to carrier.
- Cockpit view + the existing chase camera `[SHIPPED base]`.
- All ship AI (wingmen and enemies) runs on the state-machine pattern: `[M0]`

  `FORMATION → ATTACK → DEFEND → RTB`

## 3. Core Loops

**Campaign loop** `[M2]`
Overworld: collect income → build/upgrade fleets and sectors → move fleets →
battle in a contested sector → win (claim/upgrade) or lose (retreat, rebuild) →
march on the enemy home sector.

**Battle loop** `[SHIPPED]` + `[M0]`/`[M1]`
Deploy with your fleet → fight waves → command wingmen → earn minerals → pause
overlay: build towers, order squadrons, produce units → push the enemy ring →
destroy all shipyards → sector secured.

## 4. The "Mini" Contract (hard caps)

These caps are a design principle, not a starting point. Any feature that breaks
one needs a design argument:

| System | Cap |
|---|---|
| Factions | 2 |
| Sectors on the map | 12 |
| Wingmen | 3 |
| Tower types | 3 (gun, missile, shield) |
| Buildable unit types | 3 (fighter wing, drone wing, bomber) |
| Fleet size per side | 10 units |
| Concurrent battles | 1 |
| Active enemy ships per battle | ~40 |

## 5. Factions & Units

| Unit | Role | Notes |
|---|---|---|
| Drone (Challenger) | Swarm kamikaze | `[SHIPPED]` enemy |
| Striker | Fast weaver, rams | `[SHIPPED]` enemy, wave 3+ |
| Cruiser (Cursier) | Tanky gun platform | `[SHIPPED]` enemy, wave 5+ |
| Shipyard | Wave source, objective | `[SHIPPED]` enemy station |
| Fighter wing | Your wingmen + buildable squadron | `[M0]` AI + `[M1]` production |
| Drone wing | Cheap buildable squadron | `[M1]` |
| Bomber | Slow, anti-station payload | `[M1]`/`[M2]` |
| Carrier | Mobile production/base | `[M1]` |

## 6. Damage System `[SHIPPED]` (issue #18)

Reusable, inheritance-free, Resource-based:

- **`DamageType`** (Resource) — `kinetic`, `energy`, `heat`, `radiation`.
- **`DamageInstance`** (Resource) — a `DamageType` + an amount.
- **`Resistances`** (Resource) — per-type reduction map (0 = full, 1 = immune).
- **`DamageSystem`** (Node component) — attach as a child named `DamageSystem`.
  Exports `max_health`, `resistances`, `mineral_reward`, `death_faction`.
  Signals: `damaged`, `health_changed`, `healed`, `died`.

Death bookkeeping: `Events.entity_died(system)` → `GameState`.

| Entity | HP | Kin | En | Heat | Rad | Reward |
|---|---|---|---|---|---|---|
| Drone | 100 | 25% | 10% | 20% | 0% | 50 |
| Striker | 120 | 10% | 30% | 0% | 0% | 100 |
| Cruiser | 800 | 15% | 50% | 30% | 10% | 300 |
| Shipyard | 3000 | 20% | 20% | 20% | 20% | 2000 |
| Gun/Missile station | 1500/1200 | 20% | 20% | 20% | 20% | — |
| Sector Core | 5000 | 10% | 10% | 10% | 10% | — |
| Player | 1000 | 20% | 40% | 30% | 30% | — |

Collision layers (faction safety is enforced by masks — a bullet can never hit
its own side):

| Layer | Value | Contents |
|---|---|---|
| 1 | 1 | Player ship |
| 2 | 2 | Enemy ships |
| 3 | 4 | Player stations (core, towers) |
| 4 | 8 | Enemy stations (shipyards) |
| 5 | 16 | Asteroids (visual only) |
| 6 | 32 | Bullets/missiles |

## 7. Ship AI — State Machines `[M0]` (issue #20)

Shared lightweight FSM for wingmen and enemies (replaces the ad-hoc steering):

- **FORMATION** — hold a slot relative to the leader (left/right/rear), match velocity.
- **ATTACK** — dogfight the assigned target: intercept, lead with `get_aim_at_point()`,
  break off at minimum range, strafe while on cooldown.
- **DEFEND** — orbit the assigned object (core/carrier), engage hostiles within range.
- **RTB** — disengage, return to the carrier/formation point, land/despawn.

Enemy squadrons reuse the same states with different parameters (no wingman
commands — the enemy campaign AI `[M2]` assigns them objectives).

## 8. Economy

- **Treasury** is faction-wide `[M2]`; during battles it is `GameState.minerals`.
- **Income:** owned sectors pay minerals/minute on the overworld; kills and wave
  clears pay in battle `[SHIPPED]`.
- **Costs** `[SHIPPED]`: Gun station 1000, Missile station 1500, starting 10,000.
- **Planned** `[M1]`/`[M2]`: fighter wing ~500, drone wing ~250, bomber ~1200,
  carrier repair, sector upgrades (extractor level 1–3, shipyard level 1–3,
  tower battery level 1–3).

## 9. Persistence & Save `[M2]` (issue #23)

- Owned sectors keep towers + garrison between battles; damaged structures repair
  over time on the overworld.
- Fleet units persist (composition + hull HP); survivors of a lost sector retreat.
- Save format: JSON or ConfigFile — overworld graph state, fog of war, treasury,
  fleets, sector layouts, campaign flags. One slot + autosave.

## 10. UI & Controls

**Current** `[SHIPPED]` — W/S pitch+throttle, A/D yaw, Q/E roll, Shift boost,
Space fire, B build menu, 1/2 select tower, Enter place, Esc cancel/pause, R retry.
Gamepad: A/B throttle, right stick yaw, RB fire, View build menu, X/Y towers,
Start pause.

**Planned** `[M0]` — wingman command menu: hold **Q** (keyboard) / **LB** (gamepad)
→ radial or list (Attack target / Form up / Break / Defend core / RTB); release
to confirm.

**Planned** `[M1]` — command overlay: hold **Tab** (keyboard) / **Select** (gamepad)
→ pause → free cursor for tower placement, squadron orders, production queue.

UI standards: 720p-safe layouts, font sizes ≥ 14pt, gamepad-first menus, all
actions reachable by keyboard, gamepad, and mouse.

## 11. Platform — PC & Steam Deck

This design (WC + RTS + 4X) is the most PC-native possible. **Mobile is out of
scope** for the core game:

- 6DOF flight and simultaneous multi-axis control need a keyboard/gamepad.
- 300–500 unit engagement ranges are legible on a monitor or the Deck's 7" screen.
- 15–60 min battles + campaign sessions don't fit mobile session patterns.
- "Sell binaries + open source" matches PC stores (itch/Steam) far better than
  app-store monetization norms.

**Steam Deck is the design target**: 720p-safe UI, gamepad-first, pausable
overlays (perfect for Deck), stable 40–60 fps, offline save.

## 12. Roadmap

| Milestone | Content | Issues |
|---|---|---|
| **M0 — Wingmen** | Wingman FSM, formation slots, command menu (kb + gamepad), 3 wingmen, enemy squadrons on same AI | #19, #20 |
| **M1 — Command overlay** | Pause overlay: squadron orders, unit production, carrier as mobile base | #19, #16 (partial) |
| **M2 — Campaign** | Sector map, fleets, fog of war, income, upgrades, garrison persistence, enemy campaign AI, save/load | #16, #23 |
| **M3 — Ship & polish** | Cockpit view, shield tower, balance/audio pass, Steam Deck pass, itch/Steam release | #10 (full) |

Done: #12 (Godot 4), #18 (damage system), #10 (chase camera base).

## 13. Testing

- `test/unit_tests.gd` (+ `unit_runner.tscn`) — damage-system unit tests.
  `godot --headless --path . res://test/unit_runner.tscn`
- `test/smoke_launcher.tscn` (+ `smoke_launcher.gd`, `smoke_core.gd`) — boots the
  real game scene and drives a full gameplay arc (wave → clear → tower → victory).
  `godot --headless --path . res://test/smoke_launcher.tscn`
- **M0 adds:** unit tests for the wingman FSM (state transitions, slot math,
  command handling) and a smoke check that wingmen spawn, form up, and obey
  "attack my target".
- **M2 adds:** campaign simulation smoke test (scripted AI-vs-AI campaign run).
