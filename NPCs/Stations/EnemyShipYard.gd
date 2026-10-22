extends Station
## Enemy shipyard: wave spawn point and primary objective.
## Destroying all shipyards wins the sector.

func _ready() -> void:
	add_to_group("enemy_stations")
	$DamageSystem.died.connect(_on_died)

func _on_died() -> void:
	queue_free()
