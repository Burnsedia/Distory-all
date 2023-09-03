extends Camera3D

@export var weight = 0.8

func _ready():
	set_as_top_level(true)

func _process(delta):
	var target = get_parent().global_transform
	global_transform = global_transform.interpolate_with(target, weight)
	
