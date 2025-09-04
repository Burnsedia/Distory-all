extends Node3D

@export var hp = 100

func take_damage(damage):
	hp -= damage
	if hp <=0:
		hp = 0
				
func heal(healPoints):
	hp += healPoints	
