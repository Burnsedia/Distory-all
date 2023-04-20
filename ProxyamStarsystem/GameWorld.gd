extends Node3D


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
  spawn_stations()
  spawn_asteroids()

func spawn_stations() -> void:
	var count = 10
	var radius = 500.0
	var center = Vector3()
	# Get how much of an angle objects will be spaced around the circle.
	# Angles are in radians so 2.0*PI = 360 degrees
	var angle_step = 2.0*PI / count
	var angle = 0
	# For each node to spawn
	for i in range(0, count):
		var direction = Vector3(cos(angle), 0, sin(angle))
		var pos = center + direction * radius
		var node = preload("res://NPCs/Stations/EnemyShipYard.tscn").instantiate()
		node.global_translate(pos)
		add_child(node)
		# Rotate one step
		angle += angle_step

func spawn_asteroids() -> void:
	var count = 1000
	var radius = 650.0
	var center = Vector3()
	# Get how much of an angle objects will be spaced around the circle.
	# Angles are in radians so 2.0*PI = 360 degrees
	var angle_step = 2.0*PI / count
	var angle = 0
	# For each node to spawn
	for i in range(0, count):
		var direction = Vector3(cos(angle), randf_range(-angle, angle), sin(angle))
		var pos = center + direction * radius
		var node = preload("res://ECS/Asteroid.tscn").instantiate()
		node.global_translate(pos)
		add_child(node)
		# Rotate one step
		angle += angle_step
