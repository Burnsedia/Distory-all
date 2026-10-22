extends StaticBody3D
## The Sector Core — the thing every wave wants dead. If it dies, you lose.

func _ready() -> void:
	Global.maintower = self
	add_to_group("player_stations")
	$DamageSystem.died.connect(_on_died)

func _on_died() -> void:
	# The core is not freed immediately so the death moment stays visible.
	visible = false
