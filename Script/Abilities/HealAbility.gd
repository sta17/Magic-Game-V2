@tool
extends AbilityData
class_name HealAbility

@export var heal_amount: float = 50.0

func _init() -> void:
	slot_name = "Medicine"
	description  = "Heal: %d HP" % int(heal_amount)

func execute(_player: Player) -> void:
	_player.heal(heal_amount)
