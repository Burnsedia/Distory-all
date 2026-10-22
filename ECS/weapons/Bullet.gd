extends Area3D
class_name Bullet
## A fast kinetic/energy projectile. Configured at spawn time by Weapon.

@export var speed: float = 1600.0
@export var damage: float = 10.0
@export var damage_type: DamageType
@export var faction: StringName = &"player"
@export var lifetime: float = 2.5

## Layer bits this bullet may hit:
## player bullets -> enemy ships (bit 1) | enemy stations (bit 3)
const ENEMY_MASK := (1 << 1) | (1 << 3)
## enemy bullets -> player ship (bit 0) | player stations (bit 2)
const PLAYER_MASK := (1 << 0) | (1 << 2)

var _configured: bool = false

func _ready() -> void:
	Global.bulletCount += 1
	if damage_type == null:
		damage_type = DamageTypes.KINETIC
	if not _configured:
		configure(damage, damage_type, faction, speed)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

## Sets damage/type/faction/speed and the collision mask. Call at spawn.
func configure(p_damage: float, p_type: DamageType, p_faction: StringName, p_speed: float) -> void:
	_configured = true
	damage = p_damage
	damage_type = p_type
	faction = p_faction
	speed = p_speed
	collision_mask = ENEMY_MASK if faction == &"player" else PLAYER_MASK

func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta

func _on_bullet_body_entered(body: Node3D) -> void:
	Global.bulletCount -= 1
	DamageSystem.apply(body, DamageInstance.new(damage_type, damage))
	queue_free()
