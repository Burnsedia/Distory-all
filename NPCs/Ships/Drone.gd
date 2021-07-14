extends KinematicBody
class_name Drone


# Declare member variables here. Examples:
var target = null
var faction = null
var velocity:Vector3 = Vector3.ZERO

var accerleration = Vector3.ZERO
var speed:float = 50.0

var steer_force:float = 5.0
var move_vec:Vector3 = Vector3.ZERO
var target_vec = null
var num_rays = 8

# context array
var ray_directions = []
var interest = []
var danger = []
var chosen_dir = Vector3.ZERO
var look_ahead = 1000
var max_speed = 100



# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("enemies")

# Physics Function
func _physics_process(delta:float) -> void:
#	set_interest()
#	set_danger()
#	choose_direction()
#	var desired_velocity = chosen_dir.rotated(rotation) * max_speed
#	velocity = velocity.linear_interpolate(desired_velocity, steer_force)
#	move_and_collide(velocity * delta)
	move_vec = vec_to_target()
	move_and_collide(move_vec * speed * delta)

func vec_to_target() -> Vector3:
	var vec_to_target = target.translation - translation
	return vec_to_target.normalized()

func set_interest() -> void:
	for i in num_rays:
		var d = ray_directions[i].rotated(rotation).dot(vec_to_target())
		
	
func set_defalt_intrest() -> void:
	pass

func set_danger() -> void:
	var space_state = get_world().direct_space_state
	for i in num_rays:
		var result = space_state.intersect_ray(translation,translation + ray_directions[i].rotated(rotation) * look_ahead,[self])
		danger[i] = 1.0 if result else 0.0

func choose_direction():
	# Eliminate interest in slots with danger

	for i in num_rays:
		if danger[i] > 0.0:
			interest[i] = 0.0
	# Choose direction based on remaining interest

	chosen_dir = Vector3.ZERO
	for i in num_rays:
		chosen_dir += ray_directions[i] * interest[i]
	chosen_dir = chosen_dir.normalized()

func set_target(t) -> void:	
	target = t
	if target != null:
		print('target set')
	
