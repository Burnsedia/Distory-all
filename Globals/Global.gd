extends Node


# Declare member variables here. Examples:
var player = null
var stationSpawnPoint = null
var maintower = null
var droinCount = 0
var bullitCount = 0

#Econemy
var startingMinerals = 10000
var curentMinerals = 0

var gunStationCost = 1000

const maxDroinds = 600
const maxbullets = 10000

var missileStation
var gunStation = preload("res://DefenseStation.tscn")
var currentStation =  null

# Called when the node enters the scene tree for the first time.
func _ready():
	curentMinerals =  startingMinerals


func placeStation(station):
	currentStation = station
	get_tree().get_root().add_child(currentStation)
	currentStation.position.x = player.transform.origin.x
	currentStation.position.y = player.transform.origin.y
	currentStation.position.x = player.transform.origin.z + 5
	currentStation.add_to_group("player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if droinCount <= 0:
		droinCount = 0
	if bullitCount <= 0:
		bullitCount = 0

func get_aim_at_point(target, bullitSpeed,firePoint):
	if !target.has_method("get_velocity"):
		return target.global_transform.origin
	
	var Pti = target.global_transform.origin
	var Pbi = firePoint.global_transform.origin
	var D = Pti.distance_to(Pbi)
	var Vt = target.get_velocity()
	var St = Vt.length()
	var Sb = bullitSpeed
	var cos_theta = Pti.direction_to(Pbi).dot(Vt.normalized())
	var q_root = sqrt(2*D*St*cos_theta + 4*(Sb*Sb - St*St)*D*D )
	var q_sub = (2*(Sb*Sb - St*St))
	var q_left = -2*D*St*cos_theta
	var t1 = (q_left + q_root) / q_sub
	var t2 = (q_left - q_root) / q_sub
	
	var t = min(t1, t2)
	if t < 0:
		t = max(t1, t2)
	if t < 0:
		return Vector3.INF # can't hit, target too fast
	
	return Vt * t + Pti
