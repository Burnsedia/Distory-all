extends Node
## Spawner — the single facade for spawning ephemeral things.
##
## It owns the live-projectile count (capped by Global.BULLET_MAX) and recycles
## projectiles through a lazy object pool, so weapons never allocate on the hot
## path. Ships/stations pool here between waves once those spawn paths route
## through spawn_unit() (WaveDirector).
##
## Nodes request; the Spawner answers. It does not dictate behaviour.
## The singleton name "Spawner" (the autoload) is the reference point for
## requesting spawns; no class_name here so it cannot collide with the autoload.

const BULLET_SCENE := preload("res://ECS/weapons/Bullet.tscn")
const MISSILE_SCENE := preload("res://ECS/weapons/Missile.tscn")

## Upper bound on idle (dormant) projectiles retained in the pool.
@export var max_idle_projectiles: int = 2000

var _pool_root: Node3D = null
var _bullet_idle: Array = []
var _missile_idle: Array = []
var _bullet_active: int = 0

## Live projectiles currently in play (bullets + missiles).
func projectile_count() -> int:
	return _bullet_active

## Root node that keeps every pooled projectile inside the scene tree.
func pool_root() -> Node3D:
	return _pool_root

func _ready() -> void:
	_pool_root = Node3D.new()
	_pool_root.name = "PooledProjectiles"
	add_child(_pool_root)

## Pulls a pooled projectile of `template` into play at `transform`. The caller
## configures it (damage/type/faction/speed) afterwards.
func spawn_projectile(template: PackedScene, transform: Transform3D) -> Area3D:
	var inst: Area3D = _pop(template)
	if inst == null:
		inst = template.instantiate()
		_pool_root.add_child(inst)
	_bullet_active += 1
	(inst as Pooled).activate(self, transform)
	return inst

## Returns a projectile to the pool, or frees it when the pool is full.
func release_projectile(inst: Area3D) -> void:
	if not is_instance_valid(inst):
		return
	_bullet_active = maxi(0, _bullet_active - 1)
	(inst as Pooled).deactivate()
	if inst is Bullet and _bullet_idle.size() < max_idle_projectiles:
		_bullet_idle.append(inst)
	elif inst is Missile and _missile_idle.size() < max_idle_projectiles:
		_missile_idle.append(inst)
	else:
		inst.queue_free()

## Instantiates a world unit (ship/station/world object) under `parent` at
## `position`. Ships and stations pool here between waves once pooling is wired
## in — for now this is the single spawn entry point so all world spawning goes
## through one place.
func spawn_unit(scene: PackedScene, parent: Node, position: Vector3) -> Node3D:
	var node := scene.instantiate() as Node3D
	parent.add_child(node)
	node.global_position = position
	return node

func _pop(template: PackedScene) -> Node3D:
	var pool := _bullet_idle if template == BULLET_SCENE else _missile_idle
	if pool.is_empty():
		return null
	return pool.pop_back() as Node3D
