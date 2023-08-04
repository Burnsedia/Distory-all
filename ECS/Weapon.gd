class_name Weapon
extends Area3D

var bullet = preload("res://ECS/Bullet.tscn")
# Direction that the bullet will be fired
var dir = transform.basis.z
# Fires a unchared shot, no seconday abbilies
func shoot():
	# when shoot event detected, fire the weapon when 
	var bullet_inst = bullet.instance()
	get_tree().get_root().add_child(bullet_inst)
	bullet_inst.global_transform = global_transform
	$AudioStreamPlayer3D.play()
	
	
		
## Fires a charged shot, does
#func charged_shot(target=null):
#	pass
