extends Panel

func _init():
	print("Startmenu has intered the tree")

func _ready():
	print("I am at the Login Screen")

func _input(event):
	if InputEventScreenTouch:
		print(event.device)
		
func _process(_delta):
	pass
		
func _on_TouchScreenButton_pressed():
	print("I have been clicket")
	get_tree().change_scene_to_file("res://ProxyamStarsystem/GameWorld.tscn")
