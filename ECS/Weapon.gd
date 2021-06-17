class_name Weapon
extends Area


var Bullet = preload("res://ECS/bullit.tscn")

var dir = transform.basis.z
var pos = transform.origin

# Fires a unchared shot, no seconday abbilies
func shoot():
	# when shoot event detected, fire the weapon when 
	Events.emit_signal("shoot", Bullet, dir, pos )
		
#fires a charged shot, does
func charged_shot():
	pass
	
