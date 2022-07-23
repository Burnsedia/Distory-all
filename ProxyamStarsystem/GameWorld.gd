extends Spatial


## Called when the node enters the scene tree for the first time.
func _ready():
	spawn_stations()

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
		var node = preload("res://NPCs/Stations/EnemyShipYard.tscn").instance()
		node.global_translate(pos)
		add_child(node)
		# Rotate one step
		angle += angle_step
