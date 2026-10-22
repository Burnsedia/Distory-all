extends Station
class_name MissileStation
## Player-built missile battery. Slow but splashes whole clusters of enemies.

## Build cost in minerals (read by GameState when placing).
@export var cost: int = 1500

func _ready() -> void:
	add_to_group("player_stations")
	$DamageSystem.died.connect(_on_died)

func _on_died() -> void:
	queue_free()
