extends Pooled
class_name Missile
## Homing explosive projectile. Spawned via the Spawner's pooled pool.

@export var speed: float = 500.0
@export var damage: float = 150.0
@export var damage_type: DamageType = DamageTypes.HEAT
@export var splash_radius: float = 45.0
@export var faction: StringName = &"player"
@export var turn_speed: float = 3.0

var target: Node3D = null
var _exploded: bool = false
var _dir: Vector3 = Vector3.FORWARD

func activate(owner: Node, transform: Transform3D) -> void:
	super.activate(owner, transform)
	_dir = -transform.basis.z

func configure(p_damage: float, p_type: DamageType, p_faction: StringName, p_speed: float) -> void:
	if damage_type == null:
		damage_type = DamageTypes.HEAT
	damage = p_damage
	damage_type = p_type
	faction = p_faction
	speed = p_speed

func set_target(t: Node3D) -> void:
	target = t

func _physics_process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		var desired := (target.global_position - global_position).normalized()
		_dir = _dir.slerp(desired, minf(1.0, turn_speed * delta)).normalized()
	else:
		var desired := -global_transform.basis.z
		_dir = _dir.slerp(desired, minf(1.0, turn_speed * delta)).normalized()
	if _dir.length_squared() > 0.001:
		look_at(global_position + _dir, Vector3.UP)
	global_position += _dir * speed * delta
	if target != null and is_instance_valid(target):
		if global_position.distance_to(target.global_position) < 8.0:
			explode()

func _on_missile_body_entered(_body: Node3D) -> void:
	explode()

func explode() -> void:
	if _exploded:
		return
	_exploded = true
	var group_name: String = "enemies" if faction == &"player" else "player"
	for body in get_tree().get_nodes_in_group(group_name):
		var node := body as Node3D
		if node == null:
			continue
		var d := global_position.distance_to(node.global_position)
		if d <= splash_radius:
			var falloff := 1.0 - 0.5 * (d / splash_radius)
			DamageSystem.apply(node, DamageInstance.new(damage_type, damage * falloff))
	# Also splash enemy stations when fired by the player.
	if faction == &"player":
		for body in get_tree().get_nodes_in_group("enemy_stations"):
			var node := body as Node3D
			if node == null:
				continue
			var d := global_position.distance_to(node.global_position)
			if d <= splash_radius:
				var falloff := 1.0 - 0.5 * (d / splash_radius)
				DamageSystem.apply(node, DamageInstance.new(damage_type, damage * falloff))
	return_to_pool()
