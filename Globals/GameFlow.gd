extends Node
## GameFlow — the game lifecycle. Owns start/restart/over and the win/lose
## finalisation. It is the sole authority that ends a game: every other service
## only *announces* an outcome on the Events bus (`game_ended`) and reacts on
## `game_over`. GameFlow itself does not expose a signal — it broadcasts on the
## bus so every service reacts uniformly.

var game_active: bool = false
var game_ended: bool = false

func _ready() -> void:
	Events.entity_died.connect(_on_entity_died)
	Events.game_ended.connect(_finalize)

## Called once by the world when it is ready. Resets flags and broadcasts the
## start so each service can initialise itself.
func start_game(spawn_root: Node3D) -> void:
	game_active = true
	game_ended = false
	Events.game_started.emit(spawn_root)

func _on_entity_died(system: DamageSystem) -> void:
	if system == null:
		return
	match system.death_faction:
		&"core", &"player":
			Events.game_ended.emit(false)

func _finalize(won: bool) -> void:
	if game_ended:
		return
	game_ended = true
	game_active = false
	Events.game_over.emit(won)

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")
