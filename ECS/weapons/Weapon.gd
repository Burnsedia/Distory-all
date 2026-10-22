class_name Weapon
extends Area3D
## Fires bullets of a configured damage type.
## Attach as a child named "Weapon"; muzzle points along -Z.

const BulletScene := preload("res://ECS/weapons/Bullet.tscn")

@export var damage: float = 10.0
@export var damage_type: DamageType
@export var bullet_speed: float = 1600.0
## "player" bullets hit enemy ships/stations; "enemy" bullets hit the player side.
@export var faction: StringName = &"player"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	if damage_type == null:
		damage_type = DamageTypes.KINETIC

## Fires one bullet along -Z.
func shoot() -> void:
	if Global.bulletCount >= Global.BULLET_MAX:
		return
	var bullet := BulletScene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = global_transform
	bullet.configure(damage, damage_type, faction, bullet_speed)
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()

## Fires a charged shot; secondary abilities go here later.
func charged_shot(_target = null) -> void:
	pass
