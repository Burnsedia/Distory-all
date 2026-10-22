extends Station
class_name DefenseStation
## Player-built gun station. Kinetic turrets protect the sector core.

## Build cost in minerals (read by GameState when placing).
@export var cost: int = 1000

func _ready() -> void:
	add_to_group("player_stations")
	$DamageSystem.died.connect(_on_died)

func _on_died() -> void:
	queue_free()
