extends StaticBody


# Declare member variables here. Examples:
var drone = preload("res://NPCs/Challenger.tscn")
var friget = preload("res://NPCs/Ships/Cursier.tscn")
var wave_num = 1
var spawn_radius = 20
var velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.start()
	spawn_wave()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func spawn_wave():
	wave_num += 1
	var spawn_position = Vector3()
	var spawn_rotation = Vector3()
	var drones =  drone.instance()
	var frigets = friget.instance()

	for w in wave_num:
		#randomize rotation
		Global.droinCount += 1
		spawn_rotation.x = rand_range(-spawn_radius, spawn_radius)
		spawn_rotation.y = rand_range(-spawn_radius, spawn_radius)
		spawn_rotation.z = rand_range(-spawn_radius, spawn_radius)
		# randomize position
		spawn_position.x = rand_range(-spawn_radius, spawn_radius)
		spawn_position.y = rand_range(-spawn_radius, spawn_radius)
		spawn_position.z = rand_range(-spawn_radius, spawn_radius)
		# set position
		drones.translation = spawn_position
		# set rotation
		drones.rotation = spawn_rotation
		
		get_tree().get_root().add_child(drones)
	
		frigets.translation = spawn_position
		frigets.rotation = spawn_rotation

		get_tree().call_group("enemies", "set_target", Global.player)

func _on_Timer_timeout():
	if Global.droinCount <= Global.maxDroinds:
		spawn_wave()
func get_velocity():
	return self.velocity
	
func take_damage(damage):
	queue_free()
