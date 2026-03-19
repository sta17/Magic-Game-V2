@tool
extends ItemData
class_name ArmorData

@export var defense: float = 5.0          # flat damage reduction
@export var max_health_bonus: float = 0.0 # extra max HP

func _init():
	item_type = ItemType.ARMOR

func get_tooltip() -> String:
	var txt = "[b]" + item_name + "[/b]\n" + description
	txt += "\n[color=cyan]DEF:[/color] " + str(defense)
	if max_health_bonus > 0:
		txt += "  [color=green]+HP:[/color] +" + str(int(max_health_bonus))
	return txt
