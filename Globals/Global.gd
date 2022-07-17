extends Node


# Declare member variables here. Examples:
var player = null
var stationSpawnPoint = null
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


func placeStation(station):
	currentStation = station
	get_tree().get_root().add_child(currentStation)
	currentStation.translation.x = player.transform.origin.x
	currentStation.translation.y = player.transform.origin.y
	currentStation.translation.x = player.transform.origin.z + 5
	currentStation.add_to_group("player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if droinCount <= 0:
		droinCount = 0
	if bullitCount <= 0:
		bullitCount = 0
