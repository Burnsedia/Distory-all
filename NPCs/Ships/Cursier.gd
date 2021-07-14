extends KinematicBody
class_name Crusier


export var max_speed = 350
export var steer_force = 0.1
export var look_ahead = 100
export var num_rays = 16

# context array

var ray_directions = []
var interest = []
var danger = []

var chosen_dir = Vector3.ZERO
var velocity = Vector3.ZERO
var acceleration = Vector3.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	interest.resize(num_rays)
	danger.resize(num_rays)
	ray_directions.resize(num_rays)
	for i in num_rays:
		var angle = i * 2 * PI / num_rays
		ray_directions[i] = Vector3.FORWARD.rotated(Vector3.UP, angle)
		ray_directions[i] = Vector3.UP.rotated(Vector3.FORWARD, angle)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass






