extends Pooled
class_name Bullet
## Fast kinetic/energy projectile. Spawned via the Spawner's pooled pool and
## configured at spawn time by the firing weapon.

@export var speed: float = 1600.0
@export var damage: float = 10.0
@export var damage_type: DamageType
@export var faction: StringName = &"player"

## Layer bits this bullet may hit:
## player bullets -> enemy ships (bit 1) | enemy stations (bit 3)
const ENEMY_MASK := (1 << 1) | (1 << 3)
## enemy bullets -> player ship (bit 0) | player stations (bit 2)
const PLAYER_MASK := (1 << 0) | (1 << 2)

var _configured: bool = false

func configure(p_damage: float, p_type: DamageType, p_faction: StringName, p_speed: float) -> void:
	if damage_type == null:
		damage_type = DamageTypes.KINETIC
	_configured = true
	damage = p_damage
	damage_type = p_type
	faction = p_faction
	speed = p_speed
	collision_mask = ENEMY_MASK if faction == &"player" else PLAYER_MASK

func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta

func _on_bullet_body_entered(body: Node3D) -> void:
	DamageSystem.apply(body, DamageInstance.new(damage_type, damage))
	return_to_pool()
