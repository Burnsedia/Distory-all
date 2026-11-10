extends Area3D
class_name Pooled
## Base for projectiles recycled by the Spawner's object pool.
##
## The owner is any Node (currently the Spawner autoload); lifecycle is owned by
## it, not here, so dormant pooled instances stay fully quiescent (no timers, no
## movement) and the pool never leaks work on the hot path.

var _owner: Node = null
var _life_timer: Timer = null

@export var lifetime: float = 2.5

## Called by the owner to bring a pooled projectile into play.
func activate(owner: Node, transform: Transform3D) -> void:
	_owner = owner
	global_transform = transform
	monitoring = true
	process_mode = Node.PROCESS_MODE_INHERIT
	if _life_timer == null:
		_life_timer = Timer.new()
		_life_timer.name = "LifeTimer"
		_life_timer.timeout.connect(_on_life_timeout)
		if _owner != null:
			_owner.add_child(_life_timer)
	if _life_timer != null:
		_life_timer.wait_time = lifetime
		_life_timer.start()

## Called by the owner to park the projectile back in the pool.
func deactivate() -> void:
	monitoring = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if _life_timer != null:
		_life_timer.stop()

func _on_life_timeout() -> void:
	return_to_pool()

## Recycles this projectile back to its owner (or frees it if none).
func return_to_pool() -> void:
	if _owner != null and _owner.has_method("release_projectile"):
		_owner.call("release_projectile", self)
	else:
		queue_free()
