extends Node


# Declare member variables here. Examples:
var startmenu = preload("res://StartMenu.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print("I am running")
	if InputEventScreenTouch:
		print("I touch the screen")
