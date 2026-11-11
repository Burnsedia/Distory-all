extends Node
## Economy — the mineral currency. Owns the balance plus earning (death rewards,
## wave-clear bonuses) and spending. Nodes request; Economy answers. It does not
## drive behaviour — it only reports when the balance changes.

signal minerals_changed(value: int)

## Starting minerals for a fresh game.
const STARTING_MINERALS := 10000

var minerals: int = STARTING_MINERALS

## False once the game has ended; stops awards from leaking after the result.
var game_active: bool = false

func _ready() -> void:
	Events.entity_died.connect(_on_entity_died)
	Events.game_started.connect(_on_game_started)
	Events.game_ended.connect(_on_game_ended)

func _on_game_started(_spawn_root: Node3D) -> void:
	game_active = true
	minerals = STARTING_MINERALS
	minerals_changed.emit(minerals)

func award_minerals(amount: int) -> void:
	if amount <= 0:
		return
	minerals += amount
	minerals_changed.emit(minerals)

## Returns false and leaves the balance untouched when the player cannot afford it.
func spend_minerals(amount: int) -> bool:
	if minerals < amount:
		return false
	minerals -= amount
	minerals_changed.emit(minerals)
	return true

func _on_game_ended(_won: bool) -> void:
	game_active = false

func _on_entity_died(system: DamageSystem) -> void:
	if not game_active or system == null or system.mineral_reward <= 0:
		return
	award_minerals(system.mineral_reward)
