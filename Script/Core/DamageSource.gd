extends Node3D
class_name DamageSource

@export var entity: CharacterBody3D
@export var can_damage: bool = false
@export var attack_component: AttackComponent

var instance: int = 0

## Logic when this damage source successfully hits an entity
## Returns whether its going to free itsself
func hit_considered() -> bool:
	# meant to be overridden
	return false
