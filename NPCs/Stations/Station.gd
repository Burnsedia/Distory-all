extends StaticBody3D
class_name Station

@export var hp:int = 500
@export var maxhp:int = 600
var velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float) -> void:
	pass
	
func get_velocity():
	return self.velocity
