extends StaticBody3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var hp:int = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func take_damage(damage:int) -> void:
	if hp <= 0:
		queue_free()
	else:
		hp - damage
