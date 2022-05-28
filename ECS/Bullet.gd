extends Area
class_name Bullet

var BULLET_SPEED = 1000
var BULLET_DAMAGE = 15
var timer = Timer.new()
var hit_something = false

export var damage:int = 100

const KILL_TIMER = 10

func _ready():
	timer.connect("timeout", self, "_on_timer_timeout")
	timer.wait_time = KILL_TIMER
	timer.autostart = true
	Global.bullitCount += 1

func _physics_process(delta):
	var forward_dir = -global_transform.basis.z.normalized()
	global_translate(forward_dir * BULLET_SPEED * delta)

func _on_timer_timeout():
	queue_free()

func _on_bullit_body_entered(body):
	body.take_damage(damage)
	print("Hit " + body.name)
	set_process(false)
	hide()
	
	
