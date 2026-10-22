extends Node3D
## The sector combat scene. Sets the stage (asteroids, lights) and hands
## control to GameState, which owns the wave cycle and objectives.

const AsteroidScene := preload("res://ECS/Asteroid.tscn")

@onready var core: Node3D = $SectorCore

func _ready() -> void:
	spawn_asteroids()
	GameState.start_game(core, self)

func spawn_asteroids() -> void:
	var count := 350
	var base_radius := 650.0
	for i in count:
		var angle := TAU * i / count
		var direction := Vector3(cos(angle), randf_range(-0.5, 0.5), sin(angle)).normalized()
		var node := AsteroidScene.instantiate()
		node.position = direction * (base_radius + randf_range(-100.0, 120.0))
		node.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		node.scale = Vector3.ONE * randf_range(4.0, 12.0)
		add_child(node)
