extends MeshInstance3D

var damage = 100
var speed = 10000
var SHAPE = BoxShape3D.new()
var query = PhysicsShapeQueryParameters3D.new()
var traveled_distance = 0
var max_range = 10000

func _init():
	Global.bulletCount += 1
	query.set_shape(SHAPE)
	query.collide_with_bodies = true
	# query.transform = global_transform # This might not work in _init since global_transform is not ready

func _ready():
	query.transform = global_transform

func _process(delta):
	var distance = speed * delta
	var motion = -transform.basis.z * speed * delta
	global_position += motion
	traveled_distance += distance
	
	if traveled_distance > max_range:
		queue_free()
		return

	var result = get_world_3d().direct_space_state.intersect_shape(query)
	if result:
		print(result)
		# Add logic to handle collision
		queue_free()
