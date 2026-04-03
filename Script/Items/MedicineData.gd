@tool
extends ConsumableData
class_name MedicineData

@export var heal_amount: float = 50.0

func _init() -> void:
	super()
	consumable_type = ConsumableType.MEDICINE

func get_tooltip() -> String:
	var txt: String 
	txt = "[b]" + slot_name + "[/b]\n" 
	txt += get_tooltipWithoutTitle()
	return txt

func get_tooltipWithoutTitle() -> String:
	var txt: String 
	txt += get_type_String_color() + "\n"
	txt += description
	txt += "\n[color=green]Heal amount:[/color] " + str(heal_amount)
	return txt
