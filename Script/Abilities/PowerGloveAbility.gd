@tool
extends AbilityData
class_name PowerGloveAbility

@export var damage_bonus: float = 8.0

func _init() -> void:
	is_passive   = true
	slot_name = "Power Glove"
	description  = "Passive: +%d weapon damage while on hotbar" % int(damage_bonus)

func get_damage_bonus() -> float:
	return damage_bonus

func get_type_color() -> Color:
	return Color(1.0, 0.4, 0.2)
