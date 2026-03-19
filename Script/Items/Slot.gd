extends Resource
class_name Slot

@export var slot_name: String = ""
@export var description: String = ""
#@export var quantity: int = 1
@export var icon:         Texture2D = null

func get_tooltip() -> String:
	return "[b]" + slot_name + "[/b]\n" + description

func get_tooltipWithoutTitle() -> String:
	return description

func getName() -> String:
	return slot_name

## Returns the icon texture. Override in subclasses to provide a default icon.
func get_icon() -> Texture2D:
	return icon

## Border tint used by InventorySlot. Override for a custom colour.
func get_type_color() -> Color:
	return Color(1.0, 1.0, 1.0, 1.0)
