extends CharacterBody3D
class_name Crusier
## Tanky gun platform. Keeps its distance and hammers the target with energy bolts.

@export var speed: float = 12.0
@export var steer_force: float = 1.2
@export var attack_range: float = 450.0
@export var keep_range: float = 220.0
@export var bullet_speed: float = 1200.0
@export var weapon_damage: float = 30.0
@export var weapon_cooldown: float = 2.5
## Despawn beyond this distance from the sector center.
@export var leash_range: float = 900.0

var target: Node3D = null
var strafe_dir: float = 1.0

@onready var weapon: Weapon = $Weapon
@onready var cooldown: Timer = $CoolDown

func _ready() -> void:
	add_to_group("enemies")
	weapon.faction = &"enemy"
	weapon.damage = weapon_damage
	cooldown.wait_time = weapon_cooldown
	$DamageSystem.died.connect(_on_died)
	strafe_dir = 1.0 if randf() < 0.5 else -1.0
	call_deferred("_pick_target")

func _pick_target() -> void:
	if Global.maintower != null and Global.player != null:
		target = Global.maintower if randi() % 4 == 0 else Global.player
	elif Global.player != null:
		target = Global.player
	elif Global.maintower != null:
		target = Global.maintower

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_pick_target()
		if target == null:
			return
	if global_position.length() > leash_range:
		$DamageSystem.die()
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > attack_range:
		_seek(delta, target.global_position)
	elif dist < keep_range:
		_back_off(delta)
	else:
		_strafe_and_shoot(delta)

func _seek(delta: float, point: Vector3) -> void:
	var desired := (point - global_position).normalized() * speed
	_steer(delta, desired)

func _back_off(delta: float) -> void:
	var away := (global_position - target.global_position).normalized()
	var desired := (away + target.global_transform.basis.x * strafe_dir * 0.4).normalized() * speed
	_steer(delta, desired)

func _strafe_and_shoot(delta: float) -> void:
	var to_target := (target.global_position - global_position).normalized()
	var desired := (to_target * 0.3 + target.global_transform.basis.x * strafe_dir).normalized() * speed
	_steer(delta, desired)
	if cooldown.is_stopped():
		weapon.shoot()
		cooldown.start()

func _steer(delta: float, desired: Vector3) -> void:
	velocity = velocity.move_toward(desired, steer_force * speed * delta)
	if velocity.length() > 0.01:
		look_at(global_position + velocity.normalized() * 10.0, Vector3.UP)
	move_and_collide(velocity * delta)

func _on_died() -> void:
	queue_free()
