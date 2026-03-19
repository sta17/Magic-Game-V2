@tool
extends ItemData
class_name WeaponData

enum WeaponType {
	PISTOL,
	RIFLE,
	SHOTGUN,
	SNIPER
}

@export var weapon_type: WeaponType = WeaponType.PISTOL
@export var damage: float = 15.0
@export var fire_rate: float = 0.4       # seconds between shots
@export var ammo_max: int = 12
@export var ammo_current: int = 12
@export var reload_time: float = 1.5
@export var bullet_speed: float = 60.0
@export var bullet_spread: float = 0.03
@export var pellets: int = 1             # shotgun fires multiple
@export var weapon_range: float = 100.0

func _init():
	item_type = ItemType.WEAPON

func get_tooltip() -> String:
	var txt = "[b]" + item_name + "[/b]\n" + description
	txt += "\n[color=orange]DMG:[/color] " + str(damage)
	txt += "  [color=yellow]ROF:[/color] " + ("%.1f" % (1.0 / fire_rate)) + "/s"
	txt += "\n[color=cyan]AMMO:[/color] " + str(ammo_current) + "/" + str(ammo_max)
	txt += "  [color=gray]RELOAD:[/color] " + ("%.1f" % reload_time) + "s"
	if pellets > 1:
		txt += "\n[color=red]PELLETS:[/color] " + str(pellets)
	return txt

func get_weapon_type_name() -> String:
	match weapon_type:
		WeaponType.PISTOL:  return "Pistol"
		WeaponType.RIFLE:   return "Rifle"
		WeaponType.SHOTGUN: return "Shotgun"
		WeaponType.SNIPER:  return "Sniper"
	return "Unknown"
