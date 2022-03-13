extends Area

var target = Global.player
var fire_point
var bullit_speed = 1000
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("enemies")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	look_at(get_aim_at_point(), Vector3.UP)
	$Weapon.shoot()

func get_aim_at_point():
	if !target.has_method("get_velocity"):
		return target.global_transform.origin
	
	var Pti = target.global_transform.origin
	var Pbi = fire_point.global_transform.origin
	var D = Pti.distance_to(Pbi)
	var Vt = target.get_velocity()
	var St = Vt.length()
	var Sb = bullit_speed
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
