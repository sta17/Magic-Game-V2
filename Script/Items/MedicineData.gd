@tool
extends ConsumableData
class_name MedicineData

@export var heal_amount: float = 50.0

func _init() -> void:
	super()
	consumable_type = ConsumableType.MEDICINE
