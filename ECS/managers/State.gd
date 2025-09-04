extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
#func seek(delta):
	#var target_location = target.global_transform.origin
	## get desiered velocity
	#var desiered_velocity = (target_location - transform.origin).normalized() * speed
	## get diff in velocity
	#var steer = (desiered_velocity - velocity).normalized() * steer_force
	## update velocity
	#velocity += steer * delta
	## look at movement
	## move
	#move_and_collide(velocity)
#
#func attack(delta):
	#var target_location = target.global_transform.origin
	## get desiered velocity
	#var desiered_velocity = (get_aim_at_point() - transform.origin).normalized() * speed
	## get diff in velocity
	#var steer = (desiered_velocity - velocity).normalized() * steer_force
	## update velocity
	#velocity += steer * delta
	## look at movement
	#look_at(transform.origin + velocity, Vector3.UP)
	## move
#
	#move_and_collide(velocity)

#func avoid(delta):
	#var target_location = target.global_transform.origin
	## get desiered velocity
	#var desiered_velocity = (transform.origin - target_location).normalized() * speed
	## get diff in velocity
	#var steer = (desiered_velocity - velocity).normalized() * steer_force
	## update velocity
	#velocity += steer * delta
	## look at movement
	#look_at(transform.origin + velocity, Vector3.UP)
	## move	
	#move_and_collide(velocity)
