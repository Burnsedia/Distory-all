extends Node
## Global event bus. Systems emit here so they don't need direct references.

signal shoot(bullet, direction, location)
## Broadcast when any service ends a game (win or lose); finalised by GameFlow.
signal game_ended(won: bool)
## Broadcast once a game has been finalised. All services (HUD, WaveDirector,
## Build) react to this to clean up; it is emitted after the result is known.
signal game_over(won: bool)
## Broadcast once per game carrying the world root, so each service can set up.
signal game_started(spawn_root: Node3D)
## Sent by DamageSystem when an entity with a death_faction dies.
signal entity_died(system)
## One-shot announcement for the HUD banner.
signal message(text: String)
