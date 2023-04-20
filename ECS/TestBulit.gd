extends MeshInstance3D

var damage = 100
var speed= 10000
var SHAPE = BoxShape3D.new()
var query = PhysicsShapeQueryParameters3D.new()
var travile_distance = 0
var max_range = 10000
# Declare member variables here. Examples:
# var a = 2
# Called when the node enters the scene tree for the first time.
func _init():
	Global.bullitCount += 1
	query.set_shape(SHAPE)
	query.collide_with_bodies = true
	query.transform = global_transform
	query.collision_mask = 1
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var distance = speed * delta
	var motion = -transform.basis.z * speed * delta
	global_translate(motion)
	travile_distance += distance
	var reslult := get_world_3d().direct_space_state.intersect_shape(query, 1)
	print(reslult)

		
