extends Node3D

enum Plants {
	LAVA,
	SAND,
	TERESTRIAL,
	GASEOUS,
	NOATMOSPHER
}
const PlantScene  = {
	Plants.LAVA: preload("res://addons/naejimer_3d_planet_generator/scenes/planet_lava.tscn"),
	Plants.SAND: preload("res://addons/naejimer_3d_planet_generator/scenes/planet_sand.tscn"),
	Plants.TERESTRIAL: preload("res://addons/naejimer_3d_planet_generator/scenes/planet_terrestrial.tscn"),
	Plants.GASEOUS: preload("res://addons/naejimer_3d_planet_generator/scenes/planet_gaseous.tscn"),
	Plants.NOATMOSPHER: preload("res://addons/naejimer_3d_planet_generator/scenes/planet_no_atmosphere.tscn")
}
@onready var starObject = $Planets/Star 
@export var count = 8
var radius = 5000
var center = Vector3()
	# Get how much of an angle objects will be spaced around the circle.
	# Angles are in radians so 2.0*PI = 360 degrees
var angle_step = 2.0*PI / count
const lang = 1000
var angle = 0
	# For each node to spawn
var  PS = Vector3(lang,lang,lang)
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	GenStarSystem()
	
func getPlanet():
	var random_index = randi_range(0,4)
	var planet_scene = PlantScene[random_index]
	if planet_scene:
		return planet_scene.instantiate()

func GenStarSystem() -> void:
	for i in range(0, count):
		var dist = 2000
		var direction = Vector3(cos(angle), 0, sin(angle))
		var pos = center + direction * radius
		var node = getPlanet()
		node.global_translate(pos)
		node.set_scale(PS)
		add_child(node)
		print("I added a planet to the system")
		# Rotate one step
		angle += angle_step
		print(radius)
		radius += dist
		print(radius)
