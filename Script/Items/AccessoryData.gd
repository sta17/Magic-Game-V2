@tool
extends ItemData
class_name AccessoryData

@export var speed_bonus: float = 0.0    # added to move speed
@export var damage_bonus: float = 0.0  # added to all weapon damage
@export var health_regen: float = 0.0  # HP restored per second

func _init():
	item_type = ItemType.ACCESSORY

func get_tooltip() -> String:
	var txt = "[b]" + item_name + "[/b]\n" + description
	if speed_bonus != 0.0:
		txt += "\n[color=yellow]SPD:[/color] +" + ("%.1f" % speed_bonus)
	if damage_bonus != 0.0:
		txt += "  [color=orange]DMG:[/color] +" + ("%.1f" % damage_bonus)
	if health_regen > 0.0:
		txt += "\n[color=green]REGEN:[/color] " + ("%.1f" % health_regen) + " HP/s"
	return txt
