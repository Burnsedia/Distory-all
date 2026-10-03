extends CharacterBody3D
class_name Crusier

var target = null
var faction = null

var steer_vec:Vector3 = Vector3.ZERO
var acceleration_vec = Vector3.ZERO
var speed:float = 15.0
var can_shoot = false
var steer_force:float = 0.5
var move_vec:Vector3 = Vector3.ZERO
var target_vec = null
var attack_range = 400.0
var free_range = 300.0
var bullet_speed = 1200

@export var empactDamage = 1000
@export var max_speed = 20.0
@export var acceleration = 1.5

@onready var fire_point = $Weapon.global_transform
@onready var cooldown = $CoolDown
@onready var areas = [$Area3, $Area4, $Area2, $Area5, $Area6, $Area7, $Area8, $Area9]

func _ready():
	add_to_group("enemies")
	if randi()%2 == 0:
		target = Global.player
	else:
		target = Global.maintower

func _physics_process(delta:float) -> void:
	if !target:
		return
		
	var dist_to_target = global_position.distance_to(target.global_position)
	
	if dist_to_target < free_range:
		avoid(delta)
	elif dist_to_target <= attack_range:
		attack(delta)
	else:
		seek(delta)

func seek(delta):
	var target_location = target.global_position
	var desired_velocity = (target_location - global_position).normalized() * speed
	var steer = (desired_velocity - velocity).normalized() * steer_force
	
	velocity += steer + avoid_collisions() * delta
	velocity = velocity.limit_length(max_speed)
	
	look_at(global_position + velocity, Vector3.UP)
	move_and_collide(velocity * delta)

func attack(delta):
	can_shoot = true
	var aim_point = get_aim_at_point()
	
	if aim_point == Vector3.INF:
		# If we can't hit, just move towards target
		seek(delta)
		return

	var desired_velocity = (aim_point - global_position).normalized() * speed
	var steer = (desired_velocity - velocity).normalized() * steer_force
	
	velocity += steer + avoid_collisions() * delta
	velocity = velocity.limit_length(max_speed)
	
	look_at(aim_point, Vector3.UP)
	move_and_collide(velocity * delta)
	
	if can_shoot and cooldown.is_stopped():
		$Weapon.shoot()
		cooldown.start()

func avoid(delta):
	var target_location = target.global_position
	var desired_velocity = (global_position - target_location).normalized() * speed
	var steer = (desired_velocity - velocity).normalized() * steer_force
	
	velocity += steer + avoid_collisions() * delta
	velocity = velocity.limit_length(max_speed)
	
	look_at(global_position + velocity, Vector3.UP)
	move_and_collide(velocity * delta)

func get_aim_at_point():
	if !target.has_method("get_velocity"):
		return target.global_position
		
	var Pti = target.global_position
	var Pbi = fire_point.origin # Use origin of the transform
	var D = Pti.distance_to(Pbi)
	var Vt = target.get_velocity()
	var St = Vt.length()
	var Sb = bullet_speed
	var cos_theta = Pti.direction_to(Pbi).dot(Vt.normalized())
	
	# Quadratic formula for interception
	var q_root = sqrt(2*D*St*cos_theta + 4*(Sb*Sb - St*St)*D*D )
	var q_sub = (2*(Sb*Sb - St*St))
	var q_left = -2*D*St*cos_theta
	
	if q_sub == 0: return Pti
	
	var t1 = (q_left + q_root) / q_sub
	var t2 = (q_left - q_root) / q_sub
	var t = min(t1, t2)
	
	if t < 0:
		t = max(t1, t2)
	if t < 0:
		return Vector3.INF 
		
	return Vt * t + Pti

func avoid_collisions() -> Vector3:
	var avoidance_vec = Vector3.ZERO
	var count = 0
	
	for area in areas:
		var overlapping = area.get_overlapping_bodies()
		for body in overlapping:
			if body != self and body.is_in_group("enemies"):
				var diff = global_position - body.global_position
				avoidance_vec += diff.normalized()
				count += 1
	
	if count > 0:
		return (avoidance_vec / count).normalized() * steer_force
	return Vector3.ZERO

func take_damage(damage):
	# Placeholder for actual health logic
	queue_free()
