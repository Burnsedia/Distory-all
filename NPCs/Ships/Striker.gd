extends CharacterBody3D
class_name Striker
## Fast kamikaze interceptor. Weaves on approach and detonates on contact.
## No guns — pure speed and impact.

@export var speed: float = 30.0
@export var steer_force: float = 2.5
@export var weave_frequency: float = 2.2
@export var weave_amplitude: float = 6.0
@export var ram_range: float = 40.0
@export var impact_damage: float = 300.0
## Despawn beyond this distance from the sector center.
@export var leash_range: float = 900.0

var target: Node3D = null
var _time: float = 0.0
var _weave_dir: Vector3 = Vector3.RIGHT

func _ready() -> void:
	add_to_group("enemies")
	Global.droneCount += 1
	$DamageSystem.died.connect(_on_died)
	call_deferred("_pick_target")

func _pick_target() -> void:
	if Global.maintower != null and Global.player != null:
		target = Global.player if randi() % 3 == 0 else Global.maintower
	elif Global.player != null:
		target = Global.player
	elif Global.maintower != null:
		target = Global.maintower

func _physics_process(delta: float) -> void:
	_time += delta
	if target == null or not is_instance_valid(target):
		_pick_target()
		if target == null:
			return
	if global_position.length() > leash_range:
		$DamageSystem.die()
		return
	var to_target := (target.global_position - global_position).normalized()
	var weave := _weave_dir * sin(_time * weave_frequency) * weave_amplitude
	var desired := (to_target * speed + weave).normalized() * speed
	velocity = velocity.move_toward(desired, steer_force * speed * delta)
	if velocity.length() > 0.01:
		look_at(global_position + velocity.normalized() * 10.0, Vector3.UP)
	move_and_collide(velocity * delta)
	if global_position.distance_to(target.global_position) < ram_range:
		_ram()

func _ram() -> void:
	if target != null and is_instance_valid(target):
		if target.is_in_group("player") or target.is_in_group("player_stations"):
			DamageSystem.apply(target, DamageInstance.new(DamageTypes.KINETIC, impact_damage))
	$DamageSystem.die()

func _on_Area_body_entered(body: Node3D) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.is_in_group("player_stations"):
		DamageSystem.apply(body, DamageInstance.new(DamageTypes.KINETIC, impact_damage))
	$DamageSystem.die()

func _on_died() -> void:
	Global.droneCount = maxi(0, Global.droneCount - 1)
	queue_free()
