@tool
extends ConsumableData
class_name GrenadeData

@export var damage: float           = 80.0
@export var explosion_radius: float = 5.0
@export var throw_speed: float      = 14.0

func _init() -> void:
	super()
	consumable_type = ConsumableType.GRENADE
