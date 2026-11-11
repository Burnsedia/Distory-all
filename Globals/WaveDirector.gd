extends Node
## WaveDirector — the wave cycle. Owns the spawn queue, the live-enemy and
## shipyard counts, and the win condition (all shipyards destroyed). Every
## ship/station it creates routes through Spawner so all world spawning shares
## one entry point. Coordinates with the other services via the Events bus.

signal wave_changed(wave: int)
signal enemies_changed(remaining: int)
signal shipyards_changed(remaining: int)

const DRONE_SCENE := preload("res://NPCs/Challenger.tscn")
const STRIKER_SCENE := preload("res://NPCs/Striker.tscn")
const CRUISER_SCENE := preload("res://NPCs/Ships/Cursier.tscn")
const SHIPYARD_SCENE := preload("res://NPCs/Stations/EnemyShipYard.tscn")

const SHIPYARD_COUNT := 10
const SHIPYARD_RADIUS := 500.0
const FIRST_WAVE_DELAY := 8.0
const WAVE_DELAY := 12.0
const SPAWN_INTERVAL := 0.8

# Wave state
var wave: int = 0
var wave_state: String = "idle" # idle | spawning | fighting | intermission
var enemies_alive: int = 0
var pending_spawns: Array = []
var shipyards_alive: int = 0
var spawn_root: Node3D = null

# Self-tracked lifecycle so this service can gate its own logic without a
# direct reference to GameFlow.
var game_active: bool = false
var game_ended: bool = false

var _spawn_timer: Timer
var _intermission_timer: Timer

func _ready() -> void:
	Events.entity_died.connect(_on_entity_died)
	Events.game_started.connect(_on_game_started)
	Events.game_over.connect(_on_game_over)
	_spawn_timer = _one_shot(false, SPAWN_INTERVAL)
	_spawn_timer.timeout.connect(_spawn_from_queue)
	add_child(_spawn_timer)
	_intermission_timer = _one_shot(true, WAVE_DELAY)
	_intermission_timer.timeout.connect(_on_intermission_end)
	add_child(_intermission_timer)

func _one_shot(one_shot: bool, wait_time: float) -> Timer:
	var t := Timer.new()
	t.one_shot = one_shot
	t.wait_time = wait_time
	return t

func _on_game_started(spawn_root_node: Node3D) -> void:
	spawn_root = spawn_root_node
	wave = 0
	wave_state = "idle"
	enemies_alive = 0
	pending_spawns.clear()
	_spawn_timer.stop()
	game_active = true
	game_ended = false
	shipyards_alive = 0
	_spawn_shipyards()
	_intermission_timer.start(FIRST_WAVE_DELAY)

func _spawn_shipyards() -> void:
	shipyards_alive = 0
	for i in SHIPYARD_COUNT:
		var angle := TAU * i / SHIPYARD_COUNT
		var pos := Vector3(cos(angle), 0.0, sin(angle)) * SHIPYARD_RADIUS
		Spawner.spawn_unit(SHIPYARD_SCENE, spawn_root, pos)
		shipyards_alive += 1
	shipyards_changed.emit(shipyards_alive)

# ------------------------------------------------------------------ waves

func _wave_composition(n: int) -> Array:
	var comp: Array = []
	var drones := mini(4 + 2 * n, 24)
	for i in drones:
		comp.append(DRONE_SCENE)
	if n >= 3:
		var strikers := mini(n - 2, 8)
		for i in strikers:
			comp.append(STRIKER_SCENE)
	if n >= 5:
		var cruisers := mini(int((n - 4) / 2.0), 4)
		for i in cruisers:
			comp.append(CRUISER_SCENE)
	return comp

func _begin_wave() -> void:
	if game_ended or not game_active:
		return
	wave += 1
	wave_changed.emit(wave)
	wave_state = "spawning"
	pending_spawns = _wave_composition(wave)
	Events.message.emit("WAVE %d INBOUND" % wave)
	_spawn_from_queue()
	_spawn_timer.start()

func _spawn_from_queue() -> void:
	if game_ended or not game_active:
		_spawn_timer.stop()
		return
	if pending_spawns.is_empty():
		_spawn_timer.stop()
		if wave_state == "spawning":
			wave_state = "fighting"
		return
	var scene: PackedScene = pending_spawns.pop_front()
	var ship: Node3D = Spawner.spawn_unit(scene, spawn_root, _spawn_position())
	enemies_alive += 1
	enemies_changed.emit(enemies_alive)

func _spawn_position() -> Vector3:
	var yards := get_tree().get_nodes_in_group("enemy_stations")
	if yards.is_empty():
		var a := randf() * TAU
		return Vector3(cos(a), 0.0, sin(a)) * (SHIPYARD_RADIUS - 80.0)
	var yard: Node3D = yards[randi() % yards.size()]
	return yard.global_position + Vector3(
		randf_range(-25.0, 25.0), randf_range(-15.0, 15.0), randf_range(-25.0, 25.0))

func _check_wave_cleared() -> void:
	if wave_state == "fighting" and enemies_alive <= 0:
		wave_state = "intermission"
		var bonus := 100 * wave
		economy.award_minerals(bonus)
		Events.message.emit("WAVE %d CLEARED  +%d MINERALS" % [wave, bonus])
		_intermission_timer.start(WAVE_DELAY)

func _on_intermission_end() -> void:
	if wave_state == "intermission":
		_begin_wave()

# ------------------------------------------------------------------ deaths

func _on_entity_died(system: DamageSystem) -> void:
	if not game_active or game_ended or system == null:
		return
	match system.death_faction:
		&"enemy":
			enemies_alive = maxi(0, enemies_alive - 1)
			enemies_changed.emit(enemies_alive)
			_check_wave_cleared()
		&"enemy_station":
			shipyards_alive = maxi(0, shipyards_alive - 1)
			shipyards_changed.emit(shipyards_alive)
			if shipyards_alive <= 0:
				Events.game_ended.emit(true)

func _on_game_over(_won: bool) -> void:
	game_active = false
	game_ended = true
	wave_state = "idle"
	_spawn_timer.stop()
	_intermission_timer.stop()
	pending_spawns.clear()

## The Economy this service requests from. Wired from the scene (sibling node);
## null only before the world has booted.
@onready var economy: Node = get_node("../Economy")
