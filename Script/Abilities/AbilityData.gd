@tool
@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends Slot
class_name AbilityData

## Base class for all player abilities.
## Create a subclass, override execute(), and add it to the player's AbilityList.

## If true, this ability applies its effect automatically while on the hotbar.
## Passive abilities do nothing when triggered with Q.
@export var is_passive: bool = false

## Called when the player activates this ability (hotbar Q, or Use button).
## Override in active ability subclasses. Passive abilities leave this as no-op.
func execute(_player: Player) -> void:
	pass

## Passive stat contributions — override whichever applies in a passive subclass.
func get_speed_bonus()  -> float: return 0.0
func get_damage_bonus() -> float: return 0.0
func get_health_regen() -> float: return 0.0

## Border tint used by InventorySlot. Override for a custom colour.
func get_type_color() -> Color:
	return Color(0.4, 0.7, 1.0)
