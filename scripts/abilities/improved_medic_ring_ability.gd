@tool
extends AbilityData
class_name ImprovedMedicRingAbility

@export var health_regen: float = 5.0

func _init() -> void:
	is_passive   = true
	ability_name = "Improved Medic Ring"
	description  = "Passive: %.1f HP/s regeneration while on hotbar" % health_regen

func get_health_regen() -> float:
	return health_regen

func get_icon() -> Texture2D:
	if icon: return icon
	var path := "res://resources/icons/medic_ring.png"
	if ResourceLoader.exists(path): return ResourceLoader.load(path) as Texture2D
	return null

func get_type_color() -> Color:
	return Color(0.0, 1.0, 0.6)
