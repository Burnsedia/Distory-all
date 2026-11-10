# Factions & Units — Game Design Document

**Scope:** Factions, the two-tag identity model, and every unit class.
**Reference:** GDD §5.
**Status:** `[SHIPPED]` enemies · `[M0]` roster/personality · `[M1]` capitals/production.

---

## 1. The two-tag identity model

Every **manned** unit carries two independent tags. Keeping them separate is the
key design decision that makes hack/bribe work without breaking identity.

| Tag | Meaning | Values | Drives |
|---|---|---|---|
| `faction` | Combat side | `player` / `enemy` | Collision masks — a bullet can never hit its own side |
| `owner` / loyalty | Who commands it | `none` / `player` / mercenary contract | Bribery, defection, roster membership |

**Invariant:** hacking or bribing flips `faction` while the hull, model, and
personality stay the same. A bribed cruiser is still a cruiser.

**Unmanned units (drones) have no crew** — therefore no `owner`/loyalty axis,
and are immune to bribery and defection (GDD §8.2).

---

## 2. Manned fighters — 1 pilot each

Skills + morale + personality drive these (see `design/03-crew-and-morale`).

| Fighter | Role | Armor | Speed | Primary skill | Notes |
|---|---|---|---|---|---|
| **Interceptor** | Air superiority, escort, hunt fighters | Light | Fast | Piloting | The player's ship |
| **Gunship** | All-rounder, workhorse | Medium | Medium | Piloting + Gunnery | Balanced |
| **Bomber** | Anti-station / anti-capital | Heavy | Slow | Gunnery | Shipyard-killer — the win condition |

The bomber is the win condition because the battle objective is "destroy all
shipyards" (GDD §2). Bombers are slow and vulnerable, so they need escorts —
this is what makes squad composition matter.

### Rock-paper-scissors

Interceptors beat gunships beat bombers beat interceptors. Crew skill
(piloting/gunnery) decides who wins a given fight, so skill genuinely matters.

---

## 3. Capital ships — multi-crew

Full crew (pilot + gunnery + engineering) → multiple wages, crew morale.

| Capital | Role | Notes |
|---|---|---|
| **Fighter carrier** | Spawns/leads fighter wings; mobile production | `[M1]` |
| **Cruiser (Cursier)** | Heavy gun platform | `[SHIPPED]` enemy / `[M1]` ally variant |
| **Big station** | Orbital heavy defense / base | `[M1]` |

Multi-crew capitals are the economic weight of the game: each wage line drains
the treasury, so fleet composition is a budgeting decision (GDD §8.1).

---

## 4. Unmanned & station units

| Unit | Role | Notes |
|---|---|---|
| Drone (Challenger) | Swarm kamikaze | `[SHIPPED]` enemy, immune to bribery |
| Striker | Fast weaver, rams | `[SHIPPED]` enemy, wave 3+ |
| Shipyard | Wave source, objective | `[SHIPPED]` enemy station |
| Drone wing | Cheap buildable squadron | `[M1]` |

---

## 5. Personality traits (M0 set)

Traits define how a crew *feels* about the war. Full behavior is in
`design/03-crew-and-morale`.

| Trait | Morale behavior | Bribeability |
|---|---|---|
| **Loyal** | Resists; needs less pay | Hard to bribe |
| **Greedy** | Morale swings on payouts | Easiest to bribe |
| **Brave** | Fights harder when out-numbered/low morale | Medium |
| **Cowardly** | Flees when damaged/low morale | Eager to flee |

---

## 6. Open questions

- Does the bomber's slowness make it a *forced* pick (only useful late), or
  should it have a role earlier?
- Should capital ships ever be bribeable, or only fighter pilots?
