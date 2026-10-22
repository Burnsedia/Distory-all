extends CharacterBody3D
class_name Drone
## Swarm kamikaze fighter. Approaches its target, strafes and shoots,
## then rams once close enough.

@export var speed: float = 16.0
@export var steer_force: float = 2.0
@export var attack_range: float = 320.0
@export var ram_range: float = 70.0
@export var bullet_speed: float = 1100.0
@export var impact_damage: float = 500.0
@export var weapon_damage: float = 10.0
@export var weapon_cooldown: float = 1.5
## Despawn beyond this distance from the sector center.
@export var leash_range: float = 900.0

var target: Node3D = null

@onready var weapon: Weapon = $Weapon
@onready var cooldown: Timer = $CoolDown
@onready var steer_rays: Array = [$SteerUp, $SteerDown, $SteerLeft, $SteerRight]

func _ready() -> void:
	add_to_group("enemies")
	Global.droneCount += 1
	weapon.faction = &"enemy"
	weapon.damage = weapon_damage
	cooldown.wait_time = weapon_cooldown
	$DamageSystem.died.connect(_on_died)
	call_deferred("_pick_target")

func _pick_target() -> void:
	if Global.maintower != null and Global.player != null:
		target = Global.maintower if randi() % 3 == 0 else Global.player
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
	elif dist > ram_range:
		_attack(delta)
	else:
		_ram(delta)

func _seek(delta: float, point: Vector3) -> void:
	var desired := (point - global_position).normalized() * speed
	_steer(delta, desired)

func _attack(delta: float) -> void:
	var aim := get_aim_at_point()
	if aim == Vector3.INF or not is_finite(aim.x):
		_seek(delta, target.global_position)
		return
	var desired := (aim - global_position).normalized() * speed
	_steer(delta, desired)
	if cooldown.is_stopped():
		weapon.shoot()
		cooldown.start()

func _ram(delta: float) -> void:
	var desired := (target.global_position - global_position).normalized() * speed * 2.2
	_steer(delta, desired)

func _steer(delta: float, desired: Vector3) -> void:
	velocity = velocity.move_toward(desired, steer_force * speed * delta)
	velocity += _avoidance()
	if velocity.length() > 0.01:
		look_at(global_position + velocity.normalized() * 10.0, Vector3.UP)
	move_and_collide(velocity * delta)

func _avoidance() -> Vector3:
	var push := Vector3.ZERO
	for ray in steer_rays:
		if (ray as RayCast3D).is_colliding():
			var to := (ray as RayCast3D).get_collision_point()
			push += (global_position - to).normalized()
	if push.length() > 0.0:
		return push.normalized() * speed * 0.8
	return Vector3.ZERO

## Interception point for leading a moving target.
func get_aim_at_point() -> Vector3:
	var Vt: Vector3 = Vector3.ZERO
	if target is CharacterBody3D:
		Vt = (target as CharacterBody3D).velocity
	var Pti: Vector3 = target.global_position
	var Pbi: Vector3 = global_position
	var St: float = Vt.length()
	if St < 1.0:
		return Pti
	var D: float = Pti.distance_to(Pbi)
	var Sb: float = bullet_speed
	var cos_theta: float = Pti.direction_to(Pbi).dot(Vt.normalized())
	var q_sub: float = 2.0 * (Sb * Sb - St * St)
	if absf(q_sub) < 0.001:
		return Pti
	var q_root: float = sqrt(maxf(2 * D * St * cos_theta + 4 * (Sb * Sb - St * St) * D * D, 0.0))
	var q_left: float = -2.0 * D * St * cos_theta
	var t1: float = (q_left + q_root) / q_sub
	var t2: float = (q_left - q_root) / q_sub
	var t: float = minf(t1, t2)
	if t < 0.0:
		t = maxf(t1, t2)
	if t < 0.0:
		return Vector3.INF
	return Vt * t + Pti

func _on_Area_body_entered(body: Node3D) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.is_in_group("player_stations"):
		DamageSystem.apply(body, DamageInstance.new(DamageTypes.KINETIC, impact_damage))
	$DamageSystem.die()

func _on_died() -> void:
	Global.droneCount = maxi(0, Global.droneCount - 1)
	queue_free()
