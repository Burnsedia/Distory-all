extends Node3D
class_name Turret
## Station-mounted gun. Scans for enemy ships in range, aims with a two-axis
## rig (Yaw/Pitch) and fires its configured projectile from the Muzzle.

@export var range: float = 350.0
@export var turn_speed: float = 2.5
@export var fire_cooldown: float = 0.8
@export var damage: float = 15.0
@export var damage_type: DamageType
@export var bullet_speed: float = 1600.0
@export var faction: StringName = &"player"
## Projectile scene fired. Defaults to the standard bullet.
@export var projectile: PackedScene

@onready var yaw_pivot: Node3D = $Yaw
@onready var pitch_pivot: Node3D = $Yaw/Pitch
@onready var muzzle: Node3D = $Yaw/Pitch/Muzzle

var target: Node3D = null
var cooldown_left: float = 0.0

func _ready() -> void:
	if projectile == null:
		projectile = preload("res://ECS/weapons/Bullet.tscn")
	if damage_type == null:
		damage_type = DamageTypes.KINETIC
	cooldown_left = randf() * fire_cooldown

func _process(delta: float) -> void:
	cooldown_left -= delta
	_update_target()
	if target == null:
		return
	_aim(delta)
	if _facing_target() and cooldown_left <= 0.0:
		_fire()

func _update_target() -> void:
	if target != null and (not is_instance_valid(target)
			or global_position.distance_to(target.global_position) > range):
		target = null
	if target != null:
		return
	var best: Node3D = null
	var best_d := range
	for ship in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_to((ship as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = ship
	target = best

func _aim(delta: float) -> void:
	var rate := minf(1.0, turn_speed * delta)
	var local := to_local(target.global_position)
	var yaw_target := atan2(local.x, -local.z)
	yaw_pivot.rotation.y = lerp_angle(yaw_pivot.rotation.y, yaw_target, rate)
	var local2 := yaw_pivot.to_local(target.global_position)
	var pitch_target := atan2(local2.y, -local2.z)
	pitch_pivot.rotation.x = lerp_angle(pitch_pivot.rotation.x, pitch_target, rate)

func _facing_target() -> bool:
	var to_target := (target.global_position - muzzle.global_position).normalized()
	var facing := -muzzle.global_transform.basis.z.normalized()
	return facing.dot(to_target) > 0.985

func _fire() -> void:
	cooldown_left = fire_cooldown
	var p := projectile.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_transform = muzzle.global_transform
	if p.has_method("configure"):
		p.configure(damage, damage_type, faction, bullet_speed)
	if p is Missile and target != null:
		p.set_target(target)
	if p.has_method("set_target") and target != null and not (p is Missile):
		p.set_target(target)
