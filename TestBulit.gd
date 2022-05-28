extends MeshInstance

var speed= 10000
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var query := PhysicsShapeQueryParameters.new()
var SHAPE := BoxShape.new()
var max_range = 1000
var travile_distance


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.bullitCount += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var distance = speed * delta
	var motion = -transform.basis.z * speed * delta
	global_translate(motion)
	travile_distance += distance
	query.set_shape(SHAPE)
	query.collide_with_bodies = true
	query.transform = global_transform
	var reslult := get_world().direct_space_state.intersect_shape(query, 1)
	if reslult or travile_distance > max_range: 
		set_process(false)
		hide()
