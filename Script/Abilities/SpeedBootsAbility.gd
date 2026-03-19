@tool
extends AbilityData
class_name SpeedBootsAbility

@export var speed_bonus: float = 1.8

func _init() -> void:
	is_passive   = true
	ability_name = "Speed Boots"
	description  = "Passive: +%.1f movement speed while on hotbar" % speed_bonus

func get_speed_bonus() -> float:
	return speed_bonus

func get_icon() -> Texture2D:
	if icon: return icon
	var path := "res://resources/icons/speed_boots.png"
	if ResourceLoader.exists(path): return ResourceLoader.load(path) as Texture2D
	return null

func get_type_color() -> Color:
	return Color(0.3, 1.0, 0.5)
