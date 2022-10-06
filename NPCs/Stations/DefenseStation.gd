extends Station
class_name DefenseStation
var target = null
var mineralCost = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_Detection_body_entered(body):
	if body.is_in_group("player"):
		return
	else:
		$Tur.target = body
		$Tur2.target = body
		$Tur2.target = body
		$Tur3.target = body
		$Tur4.target = body
		$Tur5.target = body
		
		
		
		
		
#func set_target():
#	for i in get_children():
#		i.target = target


func _on_Detection_body_exited(body):
	$Tur.target = null
	$Tur2.target = null
	$Tur2.target = null
	$Tur3.target = null
	$Tur4.target = null
	$Tur5.target = null
		
