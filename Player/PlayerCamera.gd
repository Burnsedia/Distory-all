extends Camera

var target = get_parent().transform.origin
var pos = transform.origin
var offset = pos - target

export var hieght = 4
export var distancse = 3



# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_toplevel(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	look_at_from_position(pos, target, Vector3.UP)
