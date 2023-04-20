extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("menu"):
		$VBoxContainer/HBoxContainer/Control2/StationMenu.show()
	if Input.is_action_just_pressed("selectGunStation"):
		$VBoxContainer/HBoxContainer/Control2/StationMenu.hide()
		Global.currentStation = Global.gunStation
	if Input.is_action_just_pressed("PlaceStation") and Global.curentMinerals >= Global.gunStationCost:
		var station = Global.gunStation.instantiate()
		get_tree().get_root().add_child(station)
		station.add_to_group("player")
		station.global_transform =  Global.stationSpawnPoint.global_transform
		station.rotation =  Vector3.ZERO
		Global.curentMinerals -= Global.gunStationCost
		
		
		
		
		
