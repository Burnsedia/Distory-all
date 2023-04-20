extends Area3D
class_name Bullet

@onready var timer = $Timer
@export var damage:int = 1

var BULLET_SPEED = 1000
var BULLET_DAMAGE = 1 
var hit_something = false


const KILL_TIMER = .5

func _ready():
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	Global.bullitCount += 1

func _physics_process(delta):
	var forward_dir = -global_transform.basis.z.normalized()
	global_translate(forward_dir * BULLET_SPEED * delta)

func _on_timer_timeout():
	queue_free()
	print("I am deleting myself")
	Global.bullitCount -= 1

func _on_bullit_body_entered(body):
	Global.bullitCount -= 1
	body.take_damage(damage)
	print("Hit " + body.name)
	queue_free()
