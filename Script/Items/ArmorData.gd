@tool
extends ItemData
class_name ArmorData

@export var defense: float = 5.0          # flat damage reduction
@export var max_health_bonus: float = 0.0 # extra max HP

func _init() -> void:
	item_type = ItemType.ARMOR

func get_tooltip() -> String:
	var txt: String 
	txt = "[b]" + slot_name + "[/b]\n" 
	txt += get_tooltipWithoutTitle()
	return txt

func get_tooltipWithoutTitle() -> String:
	var txt: String = ""
	txt += get_type_String_color() + "\n"
	txt += description
	txt += "\n[color=cyan]DEF:[/color] " + str(defense)
	if max_health_bonus > 0:
		txt += "  [color=green]+HP:[/color] +" + str(int(max_health_bonus))
	return txt
