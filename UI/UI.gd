extends CanvasLayer


# Declare member variables here. Examples:

@onready var StatMenu = $Panel

func _init():
	print("I am intering the tree")
# Called when the node enters the scene tree for the first time.
func _ready():
	print("I am on the Tree")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(delta):
	if Input.is_action_pressed("start-game"):
		StatMenu.visible = false
		get_tree().change_scene("res://Root.tscn")
		
