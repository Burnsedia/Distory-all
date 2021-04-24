extends KinematicBody




onready var camera:Camera = $Camera

var boosting = false
var maxSpeed = 50
var boostModiffer = 10
var minSpped = 10
var turnSpeed = 10
var accel = 10
var val = Vector3()
var pos = self.transform.origin

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Touch Screen and Keyboard, mouse and joystick
#func _input(event):
#	if event.is_action_pressed("ui_up"):
#		self.rotate_object_local(Vector3.RIGHT, .05)
		

# UI inputs	
func _unhandled_input(event):
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ui_up"):
		rotate_object_local(Vector3.RIGHT, .05)
	if Input.is_action_pressed("ui_down"):
		rotate_object_local(Vector3.RIGHT, -.05)
	if Input.is_action_pressed("ui_left"):
		rotate(Vector3.UP, .05)
	if Input.is_action_pressed("ui_right"):
		rotate(Vector3.UP, -.05)
	if Input.is_action_just_pressed("boost"):
		boosting = true
	if Input.is_action_just_released("boost"):
		boosting = false
	print(pos)

func _physics_process(delta):
	val = -transform.basis.z * maxSpeed if !boosting else -transform.basis.z * maxSpeed * boostModiffer
	move_and_collide(val * delta)
	
