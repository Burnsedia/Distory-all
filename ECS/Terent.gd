extends Area3D
class_name Turent

var target = null
var bullit_speed = 1000
@onready var fire_point = $Weapon.global_transform
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func set_target():
	get_parent()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !target:
		return
	else:
		look_at(get_aim_at_point(), Vector3.UP)
		$Weapon.shoot()



func get_aim_at_point():
	if !target:
		return 
	if is_in_group("player"):
		return
	
	var Pti = target.global_transform.origin
	var Pbi = self.global_transform.origin
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
