@tool
extends ItemData
class_name WeaponData

enum WeaponType {
	Melee,
	Ranged
}

@export var weapon_type: WeaponType = WeaponType.Melee
@export var damage: float = 15.0
@export var fire_rate: float = 0.4       # seconds between shots
@export var weapon_range: float = 100.0

@export var bullet_speed: float = 60.0
@export var bullet_spread: float = 0.03
@export var pellets: int = 1             # shotgun fires multiple

func _init() -> void:
	item_type = ItemType.WEAPON

func get_tooltip() -> String:
	var txt: String 
	txt = "[b]" + slot_name + "[/b]\n" 
	txt += get_tooltipWithoutTitle()
	return txt

func get_tooltipWithoutTitle() -> String:
	var txt: String 
	txt += get_type_String_color() + "\n"
	txt += description
	txt += "\n[color=orange]DMG:[/color] " + str(damage)
	txt += "  [color=yellow]ROF:[/color] " + ("%.1f" % (1.0 / fire_rate)) + "/s"
	if pellets > 1:
		txt += "\n[color=red]PELLETS:[/color] " + str(pellets)
	txt += get_lore()
	return txt

func get_weapon_type_name() -> String:
	match weapon_type:
		WeaponType.Melee:	return "Melee"
		WeaponType.Ranged:	return "Ranged"
	return "Unknown"
