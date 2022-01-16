extends StaticBody


# Declare member variables here. Examples:
var isDead:bool = false
export var hp:int = 500


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.MainTower = self
	add_to_group("player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func take_damage(damage):
	if hp >= 0:
		Events.emit_signal("game_over")
		queue_free()
		get_tree().paused = true
	else:
		hp - damage
		
