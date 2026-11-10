class_name Weapon
extends Area3D
## Fires projectiles of a configured damage type via the Spawner's pooled pool.
## Attach as a child named "Weapon"; muzzle points along -Z.

const BulletScene := preload("res://ECS/weapons/Bullet.tscn")

@export var damage: float = 10.0
@export var damage_type: DamageType
@export var bullet_speed: float = 1600.0
## Which projectile scene this weapon fires. Defaults to the kinetic bullet.
@export var projectile_scene: PackedScene = BulletScene
## "player" bullets hit enemy ships/stations; "enemy" bullets hit the player side.
@export var faction: StringName = &"player"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	if projectile_scene == null:
		projectile_scene = BulletScene
	if damage_type == null:
		damage_type = DamageTypes.KINETIC

## Fires one projectile along -Z through the Spawner's pooled pool.
func shoot() -> void:
	if Spawner.projectile_count() >= Global.BULLET_MAX:
		return
	var inst := Spawner.spawn_projectile(projectile_scene, global_transform)
	if inst is Bullet:
		(inst as Bullet).configure(damage, damage_type, faction, bullet_speed)
	elif inst is Missile:
		(inst as Missile).configure(damage, damage_type, faction, bullet_speed)
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()

## Fires a charged shot; secondary abilities go here later.
func charged_shot(_target = null) -> void:
	pass
