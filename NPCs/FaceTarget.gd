extends Spatial


export var turn_speed = 100.0
func face_point(point: Vector3, delta: float):
	var l_point = to_local(point)
	l_point.y = 0.0
	var turn_dir = sign(l_point.x)
	var turn_amnt = deg2rad(turn_speed * delta)
	var angle = Vector3.FORWARD.angle_to(l_point)
	
	if angle < turn_amnt:
		turn_amnt = angle
	rotate_object_local(Vector3.UP, -turn_amnt * turn_dir)
	
func is_facing_target(target_point: Vector3):
	var l_target_pos = to_local(target_point)
	return l_target_pos.z < 0 and abs(l_target_pos.x) < 1.0
