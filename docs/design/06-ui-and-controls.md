# UI & Controls — Game Design Document

**Scope:** Input model, the wingman command menu, and the command overlay.
**Reference:** GDD §10.
**Status:** `[SHIPPED]` base flight/build · `[M0]` command menu · `[M1]` overlay.

---

## 1. Design intent

Controls must support 6DOF flight *and* simultaneous management inputs. The
design targets **Steam Deck**: gamepad-first, pausable overlays, 720p-safe UI,
all actions reachable by keyboard, gamepad, and mouse.

---

## 2. Flight & combat (shipped)

| Action | Keyboard | Gamepad |
|---|---|---|
| Pitch + throttle | `W` / `S` | `A` / `B` |
| Yaw | `A` / `D` | Right stick |
| Roll | `Q` / `E` | — |
| Boost | `Shift` | — |
| Fire | `Space` | `RB` |
| Shield toggle | — | — |

## 3. Build & HUD (shipped)

| Action | Keyboard | Gamepad |
|---|---|---|
| Build menu | `B` | `View` |
| Select gun station | `1` | `X` |
| Select missile station | `2` | `Y` |
| Place / cancel | `Enter` / `Esc` | `Start` (pause) |
| Pause | `Esc` | `Start` |
| Retry (after defeat) | `R` | — |

---

## 4. Wingman command menu (`[M0]`)

Hold **Q** (keyboard) / **LB** (gamepad) → radial or list:

- Attack my target
- Form on my wing
- Break and attack
- Defend the core
- Return to carrier

Release to confirm. Maps to the AI FSM states (`05-ship-ai`).

## 5. Command overlay (`[M1]`)

Hold **Tab** (keyboard) / **Select** (gamepad) → **pause** → free cursor for:
- Tower placement
- Squadron orders ("move here / attack that")
- Production queue (carrier)

---

## 6. UI standards

- 720p-safe layouts.
- Font sizes ≥ 14pt.
- Gamepad-first menus.
- Every action reachable by keyboard, gamepad, and mouse.

---

## 7. Open questions

- Radial or list for the command menu? Radial is more immersive; list is more
  legible on the Deck's small screen.
- Should the overlay be *fully pausable* or allow "pause + peek"?
