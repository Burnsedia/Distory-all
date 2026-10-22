extends Node
## Sector Defense game director (autoload).
## Owns the wave cycle, economy, win/lose conditions and tower placement.

signal minerals_changed(value: int)
signal wave_changed(wave: int)
signal enemies_changed(remaining: int)
signal shipyards_changed(remaining: int)
signal game_over(won: bool)

const DRONE_SCENE := preload("res://NPCs/Challenger.tscn")
const STRIKER_SCENE := preload("res://NPCs/Striker.tscn")
const CRUISER_SCENE := preload("res://NPCs/Ships/Cursier.tscn")
const SHIPYARD_SCENE := preload("res://NPCs/Stations/EnemyShipYard.tscn")

const GUN_STATION := preload("res://NPCs/Stations/DefenseStation.tscn")
const MISSILE_STATION := preload("res://NPCs/Stations/MissileStation.tscn")

const STARTING_MINERALS := 10000
const SHIPYARD_COUNT := 10
const SHIPYARD_RADIUS := 500.0
const FIRST_WAVE_DELAY := 8.0
const WAVE_DELAY := 12.0
const SPAWN_INTERVAL := 0.8

## Towers must be placed inside this radius around the core.
const BUILD_RADIUS := 260.0
const CORE_MIN_DISTANCE := 40.0

# Economy
var minerals: int = STARTING_MINERALS

# Wave state
var wave: int = 0
var wave_state: String = "idle" # idle | spawning | fighting | intermission
var enemies_alive: int = 0
var pending_spawns: Array = []

# World
var core: Node3D = null
var shipyards_alive: int = 0
var game_running: bool = false
var game_ended: bool = false
var spawn_root: Node3D = null

# Tower placement
var build_mode: bool = false
var ghost: Node3D = null
var ghost_valid: bool = false
var _ghost_color: Color = Color.WHITE

var _spawn_timer: Timer
var _intermission_timer: Timer

func _ready() -> void:
	Events.entity_died.connect(_on_entity_died)
	_ensure_input_bindings()
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = SPAWN_INTERVAL
	_spawn_timer.timeout.connect(_spawn_from_queue)
	add_child(_spawn_timer)
	_intermission_timer = Timer.new()
	_intermission_timer.one_shot = true
	_intermission_timer.wait_time = WAVE_DELAY
	_intermission_timer.timeout.connect(_on_intermission_end)
	add_child(_intermission_timer)

## Ensures the required input actions exist even if project.godot bindings
## were lost or edited. (Runtime safety net; see docs/GDD.md §10.)
func _ensure_input_bindings() -> void:
	_bind_key(&"menu", KEY_ESCAPE)
	_bind_key(&"PlaceStation", KEY_B)
	_bind_key(&"selectGunStation", KEY_1)
	_bind_key(&"selectMissileStation", KEY_2)
	_bind_key(&"retry", KEY_R)
	_bind_key(&"start-game", KEY_ENTER)
	_bind_joy(&"menu", JOY_BUTTON_START)
	_bind_joy(&"PlaceStation", JOY_BUTTON_BACK)
	_bind_joy(&"selectGunStation", JOY_BUTTON_X)
	_bind_joy(&"selectMissileStation", JOY_BUTTON_Y)

func _bind_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.physical_keycode == keycode:
			return
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	InputMap.action_add_event(action, e)

func _bind_joy(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == button:
			return
	var e := InputEventJoypadButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)

func _process(_delta: float) -> void:
	if not build_mode or ghost == null or Global.player == null:
		return
	var p: Node3D = Global.player
	var forward := -p.global_transform.basis.z
	var pos := p.global_position + forward * 80.0
	if core != null:
		pos.y = core.global_position.y
	ghost.global_position = pos
	var valid := _is_position_valid(pos)
	if valid != ghost_valid:
		ghost_valid = valid
		_set_ghost_color(Color(0.2, 1.0, 0.3, 0.45) if valid else Color(1.0, 0.2, 0.2, 0.45))

# ------------------------------------------------------------------ setup

## Called by the game world when it is ready. Resets all state and begins.
func start_game(core_node: Node3D, root: Node3D) -> void:
	core = core_node
	spawn_root = root
	game_running = true
	game_ended = false
	wave = 0
	wave_state = "idle"
	enemies_alive = 0
	pending_spawns.clear()
	_spawn_timer.stop()
	build_mode = false
	if ghost != null and is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null
	minerals = STARTING_MINERALS
	minerals_changed.emit(minerals)
	_spawn_shipyards()
	_intermission_timer.start(FIRST_WAVE_DELAY)
	Events.message.emit("DEFEND THE SECTOR CORE")

func _spawn_shipyards() -> void:
	shipyards_alive = 0
	for i in SHIPYARD_COUNT:
		var angle := TAU * i / SHIPYARD_COUNT
		var pos := Vector3(cos(angle), 0.0, sin(angle)) * SHIPYARD_RADIUS
		var yard := SHIPYARD_SCENE.instantiate()
		spawn_root.add_child(yard)
		yard.global_position = pos
		shipyards_alive += 1
	shipyards_changed.emit(shipyards_alive)

# ------------------------------------------------------------------ economy

func award_minerals(amount: int) -> void:
	if amount <= 0:
		return
	minerals += amount
	minerals_changed.emit(minerals)

func spend_minerals(amount: int) -> bool:
	if minerals < amount:
		return false
	minerals -= amount
	minerals_changed.emit(minerals)
	return true

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
	if game_ended or not game_running:
		return
	wave += 1
	wave_changed.emit(wave)
	wave_state = "spawning"
	pending_spawns = _wave_composition(wave)
	Events.message.emit("WAVE %d INBOUND" % wave)
	_spawn_from_queue()
	_spawn_timer.start()

func _spawn_from_queue() -> void:
	if game_ended:
		_spawn_timer.stop()
		return
	if pending_spawns.is_empty():
		_spawn_timer.stop()
		if wave_state == "spawning":
			wave_state = "fighting"
		return
	var scene: PackedScene = pending_spawns.pop_front()
	var ship: Node3D = scene.instantiate()
	spawn_root.add_child(ship)
	ship.global_position = _spawn_position()
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
		award_minerals(bonus)
		Events.message.emit("WAVE %d CLEARED  +%d MINERALS" % [wave, bonus])
		_intermission_timer.start(WAVE_DELAY)

func _on_intermission_end() -> void:
	if wave_state == "intermission":
		_begin_wave()

# ------------------------------------------------------------------ deaths

func _on_entity_died(system: DamageSystem) -> void:
	if not game_running or game_ended:
		return
	if system == null or not is_instance_valid(system):
		return
	if system.mineral_reward > 0:
		award_minerals(system.mineral_reward)
	match system.death_faction:
		&"enemy":
			enemies_alive = maxi(0, enemies_alive - 1)
			enemies_changed.emit(enemies_alive)
			_check_wave_cleared()
		&"enemy_station":
			shipyards_alive = maxi(0, shipyards_alive - 1)
			shipyards_changed.emit(shipyards_alive)
			if shipyards_alive <= 0:
				_end_game(true)
		&"core", &"player":
			_end_game(false)

func _end_game(won: bool) -> void:
	if game_ended:
		return
	game_ended = true
	game_running = false
	wave_state = "idle"
	_spawn_timer.stop()
	_intermission_timer.stop()
	cancel_build()
	Events.message.emit("SECTOR SECURED" if won else "SECTOR LOST")
	game_over.emit(won)

# ------------------------------------------------------------------ building

## Enters build mode with a ghost preview of the given station scene.
func set_build_station(station: PackedScene) -> void:
	if not game_running or game_ended:
		return
	cancel_build()
	ghost = station.instantiate()
	ghost.process_mode = Node.PROCESS_MODE_DISABLED
	spawn_root.add_child(ghost)
	# The instanced scene's _ready may have joined gameplay groups; the ghost
	# is a preview only and must not participate in any gameplay system.
	ghost.remove_from_group("player_stations")
	ghost.remove_from_group("enemy_stations")
	ghost.remove_from_group("player")
	ghost.remove_from_group("enemies")
	_prepare_ghost(ghost)
	build_mode = true
	ghost_valid = false
	Events.message.emit("BUILD MODE — FLY TO POSITION, ENTER TO PLACE, ESC TO CANCEL")

func _prepare_ghost(node: Node3D) -> void:
	for col in node.find_children("*", "CollisionObject3D", true, false):
		col.collision_layer = 0
		col.collision_mask = 0
	_set_ghost_color(Color(1.0, 0.2, 0.2, 0.45))

func _set_ghost_color(color: Color) -> void:
	if ghost == null:
		return
	_ghost_color = color
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mi in ghost.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = mat

func _is_position_valid(pos: Vector3) -> bool:
	if core == null:
		return false
	var d := pos.distance_to(core.global_position)
	return d <= BUILD_RADIUS and d >= CORE_MIN_DISTANCE

## Attempts to place the ghost as a real station. Returns true on success.
func confirm_build() -> bool:
	if not build_mode or ghost == null:
		return false
	if not ghost_valid:
		Events.message.emit("OUT OF BUILD RANGE")
		return false
	var cost: int = ghost.get("cost") if ghost.get("cost") != null else 1000
	if not spend_minerals(cost):
		Events.message.emit("NOT ENOUGH MINERALS")
		return false
	var pos := ghost.global_position
	var scene_path: String = ghost.scene_file_path
	cancel_build()
	var station: Node3D = load(scene_path).instantiate()
	spawn_root.add_child(station)
	station.global_position = pos
	Events.message.emit("STATION ONLINE")
	return true

func cancel_build() -> void:
	build_mode = false
	ghost_valid = false
	if ghost != null and is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null

# ------------------------------------------------------------------ flow

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")
