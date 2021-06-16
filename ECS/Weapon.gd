extends Area

var builit = preload("res://ECS/bullit.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("shoot", self, "shoot")
	
# Fires a unchared shot, no seconday abbilies
func shoot():
	if Input.is_action_just_pressed("shoot"):
		builit.instance()
		get_tree().root.add_child(builit)
		

#fires a charged shot, does
func charged_shot():
	pass
	
