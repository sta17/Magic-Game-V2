extends Slot
class_name ItemData

enum ItemType {
	WEAPON,
	ARMOR,
	ACCESSORY,
	CONSUMABLE,
	MISC
}

@export var item_type: ItemType = ItemType.CONSUMABLE
@export var stackable: bool = false
@export var max_stack: int = 1
@export var quantity: int = 1

@export var dropped_item_model : PackedScene
@export var granted_ability: AbilityData = null

@export var lore : String = ""

func get_tooltip() -> String:
	var txt: String 
	txt = "[b]" + slot_name + "[/b]\n"
	txt += get_tooltipWithoutTitle()
	return txt

func get_tooltipWithoutTitle() -> String:
	var txt: String
	txt += get_type_String_color() + "\n"
	txt += description
	if !lore.is_empty():
		txt += "\n" + get_lore()
	return txt

func get_lore() -> String:
	if lore.is_empty():
		return ""
	else:
		return "\n[color=#ffcc00][b]LORE: [/b][/color]\n[color=ffdead]" + lore + "[/color]"

func get_type_color() -> Color:
	match item_type:
		ItemType.WEAPON:		return Color(1.0, 0.549, 0.0, 1.0)
		ItemType.ARMOR:			return Color(0.0, 0.6, 1.0, 1.0)
		ItemType.ACCESSORY:		return Color(0.545, 0.302, 1.0, 1.0)
		ItemType.CONSUMABLE:	return Color(0.529, 0.808, 0.922, 1.0)
		ItemType.MISC:			return Color(1.0, 1.0, 1.0, 1.0)
	return Color.WHITE

func get_type_String_color() -> String:
	var text: String = str(ItemType.keys()[item_type])
	var type_color: Color = get_type_color()
	return "[color=" + type_color.to_html() +"]" + text + "[/color]"
