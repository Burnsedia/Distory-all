extends Spatial


var bullet = preload("res://ECS/bullit.tscn")
var direction
var location
# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("shoot", self, "_on_shoot", [bullet, direction, location])

func _on_shoot(bullet, direction, location):
	var b = bullet.instance()
	add_child(b)
	b.transform.basis.z = direction
	b.transform.origin = location
	print("Fired")
