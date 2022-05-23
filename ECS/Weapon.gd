class_name Weapon
extends Area

# Bullet Prebab
var bullet = preload("res://ECS/bullit.tscn")
# Direction that the bullet will be fired
var dir = transform.basis.z
# Fires a unchared shot, no seconday abbilies
func shoot():
	# when shoot event detected, fire the weapon when 
	var bullet_inst = bullet.instance()
	get_tree().get_root().add_child(bullet_inst)
	bullet_inst.global_transform = global_transform
	$AudioStreamPlayer3D.play()
	
#	print("weapon fired")
		
## Fires a charged shot, does
#func charged_shot(target=null):
#	pass
