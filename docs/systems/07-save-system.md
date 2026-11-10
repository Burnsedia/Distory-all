# Save / Load System — System Design Document

**Scope:** What state is persisted and how, for the campaign (`[M2]`) and battle.
**Reference:** GDD §9, §11. Issue #23.
**Status:** `[M2]` — not yet implemented.

---

## 1. Design intent

Persist enough state to resume the campaign without losing progress: the
overworld map, fleet positions, sector ownership/upgrades, garrison
persistence, morale/loyalty, the treasury, and fog of war. Battle-local state
(waves, current minerals) is ephemeral and not saved.

---

## 2. What is saved

### 2.1 World / campaign (must persist)

| Category | Fields |
|---|---|
| Faction | `faction`, `treasury`, `minerals` |
| Sectors | list of sector ids: `owner`, `owned`, `level`, upgrades (`extractor`/`shipyard`/`tower_battery` L1–3) |
| Garrison | towers + garrison composition + hull HP per sector (repaired over time, `GDD §9`) |
| Fleets | fleet id, units, unit hull HP, positions on lanes |
| Crews | roster: `pilot_id`, skills, morale, personality, wage, loyalty |
| Fog of war | revealed-sector mask per faction (`GDD §1`) |
| Campaign state | home sectors, win/lose flags |

### 2.2 Battle (do NOT persist)

`GameState.wave`, `wave_state`, `minerals`, `enemies_alive`, `shipyards_alive`
are battle-local (`05-economy-system`). Only a *result* (won/lost) persists as a
campaign transition.

### 2.3 Settings (persist)

Input bindings, UI options, video/audio levels.

---

## 3. File layout

Godot's `user://` save dir:

```
user://saves/
  ├── save1.json      (one slot)
  └── meta.json       (slot metadata: time, sector count)
```

JSON is preferred over `Resource`/`.save` for diffability and versioning
(`GDD §11`, and the `VERSION.md` changelog).

---

## 4. Data structure

```gdscript
class_name SaveData
@export var version: int         # must match VERSION.md / save format
@export var timestamp: int       # unix seconds
@export var faction: Dictionary
@export var sectors: Array       # Array<Dictionary>
@export var fleets: Array        # Array<Dictionary>
@export var crews: Array         # Array<Dictionary>
@export var fog_of_war: Dictionary
@export var treasury: int
@export var settings: Dictionary
```

Each subsystem serializes its slice (`GameState` → sectors/fleets, roster →
crews, etc.). Keep the split so adding a field is localized.

---

## 5. Versioning

- `SaveData.version` must equal the current save schema version.
- On load, mismatched versions trigger a **migration** step (or a "needs
  upgrade" prompt). Track new formats in `VERSION.md`.
- Write the schema version into the file header so future edits can migrate
  old saves.

---

## 6. Save triggers

| Event | Action |
|---|---|
| Sector won/lost | write campaign transition |
| Fleet arrives at sector | write positions |
| Defection / bribe | update crews |
| Treasury income cycle | write treasury/upgrades |
| Explicit quit / menu save | full save |
| Auto-save | interval-based (throttled) |

---

## 7. Fog of war persistence

Fog of war state (`revealed` mask per faction) is part of the save
(`design/01-core-loops` §3, issue #33). On load, re-hide unrevealed sectors and
re-apply the mask.

---

## 8. Open questions

- JSON vs. binary `.save` (binary is smaller/faster but less debuggable)?
- One slot or multiple saves?
- Where do battle results get written to campaign state — in
  `GameState.game_over(won)` or in an overworld handler?
- Should saves be encrypted (AGPL-3.0 means we can't add DRM)?
