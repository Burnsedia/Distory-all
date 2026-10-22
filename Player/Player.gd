extends CharacterBody3D
## The player fighter. Freelancer-style 6DOF flight.
## W/S: pitch + throttle, A/D: yaw, Q/E: roll, Space: fire, Shift: boost.

@export var max_speed: float = 500.0
@export var acceleration: float = 0.9
@export var pitch_speed: float = 1.9
@export var roll_speed: float = 0.75
@export var yaw_speed: float = 1.75
@export var input_response: float = 8.0
@export var boost_multiplier: float = 1.6

var forward_speed: float = 0.0
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

func _ready() -> void:
	Global.player = self
	add_to_group("player")
	$DamageSystem.died.connect(_on_died)

func _on_died() -> void:
	# GameState turns this into the defeat screen; keep the body for the camera.
	visible = false

func get_input(delta: float) -> void:
	var target_speed := forward_speed
	if Input.is_action_pressed("throttle_up"):
		target_speed = max_speed
	if Input.is_action_pressed("throttle_down"):
		target_speed = 0.0
	if Input.is_action_pressed("boost"):
		target_speed = max_speed * boost_multiplier
	forward_speed = lerp(forward_speed, target_speed, acceleration * delta)

	if Input.is_action_just_pressed("shoot") and has_node("Weapon"):
		$Weapon.shoot()

	pitch_input = lerp(pitch_input,
		Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down"),
		input_response * delta)
	roll_input = lerp(roll_input,
		Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left"),
		input_response * delta)
	yaw_input = lerp(yaw_input,
		Input.get_action_strength("yaw_left") - Input.get_action_strength("yaw_right"),
		input_response * delta)

func _physics_process(delta: float) -> void:
	get_input(delta)
	transform.basis = transform.basis.rotated(transform.basis.z, roll_input * roll_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.orthonormalized()
	velocity = transform.basis.z * forward_speed
	move_and_collide(velocity * delta)
