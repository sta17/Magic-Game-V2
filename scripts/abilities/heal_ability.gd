@tool
extends AbilityData
class_name HealAbility

@export var heal_amount: float = 50.0

func _init() -> void:
	ability_name = "Medicine"
	description  = "Heal: %d HP" % int(heal_amount)

func execute(player) -> void:
	player.heal(heal_amount)

func get_icon() -> Texture2D:
	if icon:
		return icon
	var path := "res://resources/icons/medkit.png"
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null
