extends KinematicBody

onready var camera:Camera = $Camera

var boosting = false
var maxSpeed = 500
var boostModiffer = 10
var minSpped = 10
var turnSpeed = 10
var accel = 10
var val = Vector3()
var pos = self.global_transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(delta):
	if Input.is_action_pressed("ui_up"):
		rotate_object_local(Vector3.RIGHT, .01)
	if Input.is_action_pressed("ui_down"):
		rotate_object_local(Vector3.RIGHT, -.01)
	if Input.is_action_pressed("ui_left"):
		rotate(Vector3.UP, .01)
	if Input.is_action_pressed("ui_right"):
		rotate(Vector3.UP, -.01)
	if Input.is_action_just_pressed("boost"):
		boosting = true
	if Input.is_action_just_released("boost"):
		boosting = false
	if Input.is_action_just_pressed("shoot"):
		$Weapon.shoot()

func _physics_process(delta):
	val = -transform.basis.z 
	move_and_collide(val * maxSpeed * delta)
