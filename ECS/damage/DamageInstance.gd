class_name DamageInstance
extends Resource
## A single packet of damage: a DamageType plus an amount.

@export var type: DamageType
@export var amount: float = 0.0

func _init(p_type: DamageType = null, p_amount: float = 0.0) -> void:
	type = p_type
	amount = p_amount
