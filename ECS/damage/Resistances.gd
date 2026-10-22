class_name Resistances
extends Resource
## Maps damage type ids to a reduction fraction in 0..1.
## 0.0 = full damage, 1.0 = immune.
## Example: { "kinetic": 0.5, "energy": 0.1 }

@export var values: Dictionary = {}

## Returns the reduction fraction for a damage type (0..1).
func reduction_for(type: DamageType) -> float:
	if type == null:
		return 0.0
	return float(values.get(String(type.id), 0.0))

## Applies resistances to an incoming damage amount.
func apply(damage: float, type: DamageType) -> float:
	return damage * (1.0 - reduction_for(type))
