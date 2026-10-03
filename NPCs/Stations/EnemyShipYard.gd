extends StaticBody3D


# Declare member variables here. Examples:
# TODO: remake these NPCs
var drone = preload("res://NPCs/Challenger.tscn")
var friget = preload("res://NPCs/Ships/Cursier.tscn")
var wave_num = 1
var spawn_radius = 20
var velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.start()
	#spawn_wave()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func spawn_wave():
	wave_num += 1
	var spawn_position = Vector3()
	var spawn_rotation = Vector3()

	for w in wave_num:
		#randomize rotation
		Global.droneCount += 1
		spawn_rotation.x = randf_range(-spawn_radius, spawn_radius)
		spawn_rotation.y = randf_range(-spawn_radius, spawn_radius)
		spawn_rotation.z = randf_range(-spawn_radius, spawn_radius)
		# randomize position
		spawn_position.x = randf_range(-spawn_radius, spawn_radius)
		spawn_position.y = randf_range(-spawn_radius, spawn_radius)
		spawn_position.z = randf_range(-spawn_radius, spawn_radius)
		
		# set position and rotation for drone
		var drone_instance = drone.instantiate()
		drone_instance.position = spawn_position
		drone_instance.rotation = spawn_rotation
		get_tree().get_root().add_child(drone_instance)
		
		# set position and rotation for friget
		var friget_instance = friget.instantiate()
		friget_instance.position = spawn_position
		friget_instance.rotation = spawn_rotation
		get_tree().get_root().add_child(friget_instance)

		# TODO: call set_target on all enemies
		# get_tree().call_group("enemies", "set_target", Global.player)

#TODO: rework all NPC Logic
#func spawn_wave():
#	#wave_num += 1
#	#var spawn_position = Vector3()
#	#var spawn_rotation = Vector3()
#	##var drones =  drone.instance()
#	##var frigets = friget.instance()
#
#	#for w in wave_num:
#		##randomize rotation
#		#Global.droneCount += 1
#		#spawn_rotation.x = randf_range(-spawn_radius, spawn_radius)
#		#spawn_rotation.y = randf_range(-spawn_radius, spawn_radius)
#		#spawn_rotation.z = randf_range(-spawn_radius, spawn_radius)
#		## randomize position
#		#spawn_position.x = randf_range(-spawn_radius, spawn_radius)
#		#spawn_position.y = randf_range(-spawn_radius, spawn_radius)
#		#spawn_position.z = randf_range(-spawn_radius, spawn_radius)
#		## set position
#		#drones.translation = spawn_position
#		## set rotation
#		#drones.rotation = spawn_rotation
#		#
#		#get_tree().get_root().add_child(drones)
#
#		#frigets.translation = spawn_position
#		#frigets.rotation = spawn_rotation
#
#		#get_tree().call_group("enemies", "set_target", Global.player)

func _on_Timer_timeout():
	if Global.droneCount <= Global.maxDroinds:
		spawn_wave()

func get_velocity():
	return self.velocity
	
func take_damage(damage):
	queue_free()
