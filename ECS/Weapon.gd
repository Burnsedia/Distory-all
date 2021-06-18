class_name Weapon
extends Area

# Bullet Prebab
var Bullet = preload("res://ECS/bullit.tscn")
# Direction that the bullet will be fired
var dir = transform.basis.z
# Position of the object in 3d space
var pos = transform.origin

# Fires a unchared shot, no seconday abbilies
func shoot():
	# when shoot event detected, fire the weapon when 
	Events.emit_signal("shoot", Bullet, dir, pos )
		
# Fires a charged shot, does
func charged_shot(target=null):
	pass
