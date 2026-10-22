class_name DamageSystem
extends Node
## Reusable damage component. Attach as a child node named "DamageSystem"
## to anything that can take damage; no inheritance required.
## Handles resistances, health, and death bookkeeping through Events.

signal damaged(instance: DamageInstance, final_amount: float)
signal health_changed(current: float, max: float)
signal healed(amount: float)
signal died

## Maximum (and starting) health.
@export var max_health: float = 100.0
## Optional per-type resistances. Null means no resistances.
@export var resistances: Resistances
## Minerals awarded to the player when this entity dies.
@export var mineral_reward: int = 0
## Bookkeeping tag used by GameState:
## "enemy" (ship), "enemy_station" (shipyard), "player" (player ship),
## "player_station" (towers), "core" (sector core), or "" (ignored).
@export var death_faction: StringName = &""

var health: float = 0.0
var dead: bool = false

func _init() -> void:
	health = max_health

func _ready() -> void:
	health = max_health
	dead = false
	if death_faction != &"":
		died.connect(_report_death)

func _report_death() -> void:
	Events.entity_died.emit(self)

## Applies a typed damage instance. Returns the final (post-resistance) amount.
func take_damage(instance: DamageInstance) -> float:
	if dead:
		return 0.0
	var amount: float = 0.0
	var type: DamageType = null
	if instance != null:
		amount = instance.amount
		type = instance.type
		if resistances != null:
			amount = resistances.apply(amount, type)
	amount = maxf(amount, 0.0)
	health -= amount
	damaged.emit(instance, amount)
	health_changed.emit(health, max_health)
	if health <= 0.0 and not dead:
		dead = true
		health = 0.0
		health_changed.emit(health, max_health)
		died.emit()
	return amount

## Applies untyped (true) damage, bypassing resistances.
func take_damage_raw(amount: float) -> float:
	return take_damage(DamageInstance.new(null, amount))

## Restores health up to max_health. Does nothing when dead.
func heal(amount: float) -> void:
	if dead:
		return
	health = minf(health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(health, max_health)

## Kills the entity immediately (emits died exactly once).
func die() -> void:
	if dead:
		return
	dead = true
	health = 0.0
	health_changed.emit(health, max_health)
	died.emit()

## Finds the DamageSystem child of a node, if it has one.
static func find_in(node: Node) -> DamageSystem:
	if node == null:
		return null
	return node.get_node_or_null("DamageSystem") as DamageSystem

## Applies a damage instance to a node if it has a DamageSystem child.
## Returns the final amount applied (0 if the node cannot be damaged).
static func apply(node: Node, instance: DamageInstance) -> float:
	var system := find_in(node)
	if system != null:
		return system.take_damage(instance)
	return 0.0
