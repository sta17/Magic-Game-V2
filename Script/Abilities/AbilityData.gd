@tool
extends Slot
class_name AbilityData

## Base class for all player abilities.
## Create a subclass, override execute(), and add it to the player's AbilityList.

@export var ability_name: String  = ""

## If true, this ability applies its effect automatically while on the hotbar.
## Passive abilities do nothing when triggered with Q.
@export var is_passive: bool = false

## Called when the player activates this ability (hotbar Q, or Use button).
## Override in active ability subclasses. Passive abilities leave this as no-op.
func execute(player) -> void:
	pass

## Passive stat contributions — override whichever applies in a passive subclass.
func get_speed_bonus()  -> float: return 0.0
func get_damage_bonus() -> float: return 0.0
func get_health_regen() -> float: return 0.0

func getName() -> String:
	return ability_name

## Returns the icon texture. Override in subclasses to provide a default icon.
func get_icon() -> Texture2D:
	return icon

## Border tint used by InventorySlot. Override for a custom colour.
func get_type_color() -> Color:
	return Color(0.4, 0.7, 1.0)
