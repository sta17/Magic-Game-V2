@tool
extends AbilityData
class_name MedicRingAbility

@export var health_regen: float = 2.0

func _init() -> void:
	is_passive   = true
	slot_name = "Medic Ring"
	description  = "Passive: %.1f HP/s regeneration while on hotbar" % health_regen

func get_health_regen() -> float:
	return health_regen

func get_type_color() -> Color:
	return Color(0.2, 0.9, 0.4)
