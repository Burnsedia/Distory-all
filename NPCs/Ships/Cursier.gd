extends CharacterBody3D
class_name Crusier
# Declare member variables here. Examples:
#var target = null
#var faction = null
#var velocity:Vector3 = Vector3.ZERO
#
#var accerleration = Vector3.ZERO
#var speed:float = 4
#
#var can_shoot = false
#var steer_force:float = .8
#var move_vec:Vector3 = Vector3.ZERO
#var target_vec = null
#var num_rays = 8
#
#var attact_range = 300.0
#var free_range = 250.0
#
#
#
#onready var fire_point = $Weapon.global_transform
#onready var cooldown = $CoolDown
#var bullit_speed = 1000
## Called when the node enters the scene tree for the first time.
#func _ready():
#	add_to_group("enemies")
#
## Physics Function
#func _physics_process(delta:float) -> void:
#
#
#	if transform.origin.distance_to(target.transform.origin) < free_range:
#		avoid(delta)
#	elif transform.origin.distance_to(target.transform.origin) <= attact_range:
#		attack(delta)
#	else:
#		seek(delta)
#


#func get_aim_at_point():
	#if !target.has_method("get_velocity"):
		#return target.global_transform.origin
#
	#var Pti = target.global_transform.origin
	#var Pbi = fire_point.global_transform.origin
	#var D = Pti.distance_to(Pbi)
	#var Vt = target.get_velocity()
	#var St = Vt.length()
	#var Sb = bullit_speed
	#var cos_theta = Pti.direction_to(Pbi).dot(Vt.normalized())
	#var q_root = sqrt(2*D*St*cos_theta + 4*(Sb*Sb - St*St)*D*D )
	#var q_sub = (2*(Sb*Sb - St*St))
	#var q_left = -2*D*St*cos_theta
	#var t1 = (q_left + q_root) / q_sub
	#var t2 = (q_left - q_root) / q_sub

#	var t = min(t1, t2)
#	if t < 0:
#		t = max(t1, t2)
#	if t < 0:
#		return Vector3.INF # can't hit, target too fast
#
#	return Vt * t + Pti
#
#func take_damage(damage):
#	queue_free()
