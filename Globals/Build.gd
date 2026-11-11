extends Node
## Build — tower placement. Owns build mode, the ghost preview, placement
## validation and placing real stations. The ghost is a preview only: it is
## detached from every gameplay group so it never participates in combat.

const GUN_STATION := preload("res://NPCs/Stations/DefenseStation.tscn")
const MISSILE_STATION := preload("res://NPCs/Stations/MissileStation.tscn")

## Towers must be placed inside this radius around the core, and outside
## CORE_MIN_DISTANCE so they never overlap it.
const BUILD_RADIUS := 260.0
const CORE_MIN_DISTANCE := 40.0

var build_mode: bool = false
var ghost: Node3D = null
var ghost_valid: bool = false
var _ghost_color: Color = Color.WHITE
var spawn_root: Node3D = null
var game_active: bool = false

signal build_mode_changed(active: bool)

func _ready() -> void:
	Events.game_started.connect(_on_game_started)
	Events.game_over.connect(_on_game_over)

func _on_game_started(spawn_root_node: Node3D) -> void:
	spawn_root = spawn_root_node
	game_active = true
	cancel_build()

func _process(_delta: float) -> void:
	if not build_mode or ghost == null or Global.player == null:
		return
	var p: Node3D = Global.player
	var forward := -p.global_transform.basis.z
	var pos := p.global_position + forward * 80.0
	if Global.maintower != null:
		pos.y = Global.maintower.global_position.y
	ghost.global_position = pos
	var valid := _is_position_valid(pos)
	if valid != ghost_valid:
		ghost_valid = valid
		_set_ghost_color(Color(0.2, 1.0, 0.3, 0.45) if valid else Color(1.0, 0.2, 0.2, 0.45))

## Enters build mode with a ghost preview of the given station scene.
func set_build_station(station: PackedScene) -> void:
	if not game_active or Global.player == null:
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
	if Global.maintower == null:
		return false
	var d := pos.distance_to(Global.maintower.global_position)
	return d <= BUILD_RADIUS and d >= CORE_MIN_DISTANCE

## Attempts to place the ghost as a real station. Returns true on success.
func confirm_build() -> bool:
	if not build_mode or ghost == null:
		return false
	if not ghost_valid:
		Events.message.emit("OUT OF BUILD RANGE")
		return false
	var cost: int = ghost.get("cost") if ghost.get("cost") != null else 1000
	if not economy.spend_minerals(cost):
		Events.message.emit("NOT ENOUGH MINERALS")
		return false
	var pos := ghost.global_position
	var scene_path: String = ghost.scene_file_path
	cancel_build()
	Spawner.spawn_unit(load(scene_path), spawn_root, pos)
	Events.message.emit("STATION ONLINE")
	return true

func cancel_build() -> void:
	build_mode = false
	ghost_valid = false
	if ghost != null and is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null

func _on_game_over(_won: bool) -> void:
	game_active = false
	cancel_build()

## The Economy this service requests from. Wired from the scene (sibling node).
@onready var economy: Node = get_node("../Economy")
