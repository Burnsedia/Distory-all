class_name DamageType
extends Resource
## Defines a kind of damage (kinetic, energy, heat, radiation).
## Instances live in res://ECS/damage/types/ and are referenced by
## DamageInstance, Resistances and every weapon.

@export var id: StringName = &"kinetic"
@export var display_name: String = "Kinetic"
@export var color: Color = Color.WHITE

func _init(p_id: StringName = &"kinetic", p_name: String = "Kinetic", p_color: Color = Color.WHITE) -> void:
	id = p_id
	display_name = p_name
	color = p_color
