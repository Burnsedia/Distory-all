extends Node


# Declare member variables here. Examples:
var player = null
var maintower = null
var droinCount = 0
var bullitCount = 0

const maxDroinds = 600
const maxbullets = 10000

var missileStation
var gunStation = preload("res://DefenseStation.tscn")
var currentStation =  null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if bullitCount <= 0:
		bullitCount = 0
