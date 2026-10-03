extends Area3D
class_name Bullet

@onready var timer = $Timer
@export var damage:int = 1
var BULLET_SPEED = 1000
var hit_something = false

const KILL_TIMER = .5

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	Global.bulletCount += 1

func _physics_process(delta):
	var forward_dir = -global_transform.basis.z.normalized()
	global_position += forward_dir * BULLET_SPEED * delta

func _on_timer_timeout():
	Global.bulletCount -= 1
	queue_free()
	print("I am deleting myself")

func _on_bullet_body_entered(body):
	Global.bulletCount -= 1
	if body.has_method("take_damage"):
		body.take_damage(damage)
	print("Hit " + body.name)
	queue_free()
