extends Slot
class_name ItemData

enum ItemType {
	WEAPON,
	ARMOR,
	ACCESSORY,
	CONSUMABLE
}

@export var item_name: String = "Unknown Item"
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var stackable: bool = false
@export var max_stack: int = 1
@export var quantity: int = 1

@export var dropped_item_model : String = ""
@export var granted_ability: AbilityData = null

@export var lore : String = ""

func get_tooltip() -> String:
	if lore.is_empty():
		return "[b]" + item_name + "[/b]\n" + description
	else:
		return "[b]" + item_name + "[/b]\n" + description + get_lore()

func get_tooltipWithoutTitle() -> String:
	return description + get_lore()

func getName() -> String:
	return item_name

func get_lore() -> String:
	if lore.is_empty():
		return ""
	else:
		return "\n[color=#ffcc00][b]LORE: [/b][/color]\n[color=ffdead]" + lore + "[/color]"

func get_icon() -> Texture2D:
	return icon

func get_type_color() -> Color:
	match item_type:
		ItemType.WEAPON:     return Color(1.0, 0.6, 0.1)
		ItemType.ARMOR:      return Color(0.3, 0.6, 1.0)
		ItemType.ACCESSORY:  return Color(0.8, 0.3, 1.0)
		ItemType.CONSUMABLE: return Color(0.529, 0.808, 0.922, 1.0)
	return Color.WHITE
