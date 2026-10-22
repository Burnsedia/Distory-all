extends Camera3D
## Chase camera: trails behind the ship, looks ahead, and widens FOV at speed
## (Freelancer-inspired, issue #10).

@export var follow_distance: float = 16.0
@export var follow_height: float = 4.5
@export var position_weight: float = 5.0
@export var look_weight: float = 6.0
@export var fov_base: float = 75.0
@export var fov_boost: float = 12.0

var _look_dir: Vector3 = Vector3.FORWARD

func _ready() -> void:
	set_as_top_level(true)
	make_current()
	fov = fov_base

func _process(delta: float) -> void:
	var ship: Node3D = get_parent()
	if ship == null:
		return
	var ship_forward := -ship.global_transform.basis.z.normalized()
	var desired_pos := ship.global_position + ship_forward * follow_distance + Vector3.UP * follow_height
	var pos_rate := 1.0 - exp(-position_weight * delta)
	global_position = global_position.lerp(desired_pos, pos_rate)

	var desired_dir := (ship.global_position + ship_forward * 20.0) - global_position
	if desired_dir.length_squared() > 0.001:
		var look_rate := 1.0 - exp(-look_weight * delta)
		_look_dir = _look_dir.lerp(desired_dir.normalized(), look_rate).normalized()
	look_at(global_position + _look_dir, Vector3.UP)

	var speed_ratio := 0.0
	if ship is CharacterBody3D:
		speed_ratio = clampf((ship as CharacterBody3D).velocity.length() / 600.0, 0.0, 1.0)
	fov = lerpf(fov_base, fov_base + fov_boost, speed_ratio)
