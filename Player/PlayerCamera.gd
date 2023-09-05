extends Camera3D

@export var weight = 0.9

@export var lerp_speed = 3.0
@export var target_path:NodePath 
@export var offset = Vector3.ZERO

var target = null

func _ready():
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if !target:
		return
	var target_pos = target.global_transform.translated(offset)
	global_transform = global_transform.interpolate_with(target_pos, lerp_speed * delta)
#	look_at(target.global_transform.origin, Vector3.UP)

#
#func _process(delta):
#	var target = get_parent().global_transform
#	var final =  Transform3D(target.basis, target.origin + offset)
#	global_transform = global_transform.interpolate_with(final, weight)
#
#	global_rotation = get_parent().global_rotation
