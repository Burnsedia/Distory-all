extends KinematicBody
class_name Drone


# Declare member variables here. Examples:
var target = null
var val:Vector3 = Vector3.ZERO
var speed:float = 500.0
var steer:Vector3 = Vector3.ZERO
var move_vec:Vector3 = Vector3.ZERO
var target_vec = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Physics Function
func _physics_process(delta:float) -> void:
	val += move_vec
	move_and_collide(val * delta)
	
func set_target(t) -> KinematicBody:
	t = target
	return t
	

func vec_to_target() -> Vector3:
	var target_vec = target.transform.origin - self.transform.origin
	move_vec = target * steer
	return move_vec
