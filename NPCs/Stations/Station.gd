extends StaticBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var hp:int = 500
export var maxhp:int = 600
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float) -> void:
	pass

func repair_damge(rp:int) -> void:
	if hp < maxhp:
		hp + rp
	else:
		hp = maxhp

func take_damage(damage:int) -> void:
	if hp >= 0:
		queue_free()
	else:
		hp - damage
		
