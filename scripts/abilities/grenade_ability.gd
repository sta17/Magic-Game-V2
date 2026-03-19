@tool
extends AbilityData
class_name GrenadeAbility

@export var damage:      float = 80.0
@export var radius:      float = 5.0
@export var throw_speed: float = 14.0

func _init() -> void:
	ability_name = "Grenade"
	description  = "Damage: %d   Radius: %.0f m   Throw Speed: %.0f" % [int(damage), radius, throw_speed]

func execute(player) -> void:
	player.throw_grenade_ability(damage, radius, throw_speed)

func get_icon() -> Texture2D:
	if icon:
		return icon
	var path := "res://resources/icons/grenade.png"
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null
