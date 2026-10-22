extends Node3D
## Disabled pending the overworld milestone (issue #16).
## The planet-generator addon this depended on was removed from the repo.
## When the overworld lands this will generate the sector map with
## procedural primitives or a maintained addon.
@export var count := 8

func _ready() -> void:
	push_warning("SectorGenerator is disabled pending the overworld milestone (#16)")
