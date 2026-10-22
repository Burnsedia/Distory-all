extends Node
## Global event bus. Systems emit here so they don't need direct references.

signal shoot(bullet, direction, location)
signal game_over(won: bool)
## Sent by DamageSystem when an entity with a death_faction dies.
signal entity_died(system)
## One-shot announcement for the HUD banner.
signal message(text: String)
