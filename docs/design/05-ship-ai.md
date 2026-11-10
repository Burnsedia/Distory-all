# Ship AI (State Machines) — Game Design Document

**Scope:** The shared FSM that drives every ship — wingmen and enemies.
**Reference:** GDD §7.
**Status:** `[M0]`.

---

## 1. Design intent

All ship AI (wingmen and enemies) runs on one **shared lightweight FSM** — the
"state machine pattern" (issue #20). Wingmen and enemies reuse the same states
with different parameters. Enemy squadrons don't accept player commands; the
enemy campaign AI assigns them objectives.

```
FORMATION → ATTACK → DEFEND → RTB
```

---

## 2. The four states

| State | Behavior |
|---|---|
| **FORMATION** | Hold a slot relative to the leader (left/right/rear), match velocity |
| **ATTACK** | Dogfight the assigned target: intercept, lead the shot, break off at min range, strafe on cooldown |
| **DEFEND** | Orbit the assigned object (core/carrier), engage hostiles within range |
| **RTB** | Disengage, return to the carrier/formation point, land/despawn |

---

## 3. Wingman commands → states

The wingman command menu (`06-ui-and-controls`, `[M0]`) maps onto these states:

| Command | Target state |
|---|---|
| Attack my target | ATTACK (shared target) |
| Form on my wing | FORMATION |
| Break and attack | ATTACK (independent targets) |
| Defend the core | DEFEND (core) |
| Return to carrier | RTB |

---

## 4. Enemy use

Enemy ships run the same FSM with different parameters:
- No player commands — objectives come from the campaign AI (`01-core-loops`).
- Formation slots and attack aggression differ per class (drone swarm vs.
  striker weaver vs. cruiser line).

---

## 5. Open questions

- How many simultaneous targets can an ATTACK-state ship track, and what
  happens when its target dies?
- Should DEFEND have a "last stand" behavior where low-morale crews refuse to
  RTB?
