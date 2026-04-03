@tool
extends AbilityData
class_name SpeedBootsAbility

@export var speed_bonus: float = 1.8

func _init() -> void:
	is_passive   = true
	slot_name = "Speed Boots"
	description  = "Passive: +%.1f movement speed while on hotbar" % speed_bonus

func get_speed_bonus() -> float:
	return speed_bonus

func get_type_color() -> Color:
	return Color(0.3, 1.0, 0.5)
