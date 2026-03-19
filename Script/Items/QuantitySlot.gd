extends Slot
class_name QuantitySlot

@export var item: ItemData
@export var quantity: int = 1

func get_tooltip() -> String:
	return item.get_tooltip() + "\nUses Left: " + str(quantity) 

func getName() -> String:
	return item.item_name

func get_icon() -> Texture2D:
	return item.icon

func get_tooltipWithoutTitle() -> String:
	return item.get_tooltipWithoutTitle() + "\nUses Left: " + str(quantity) 

func get_type_color() -> Color:
	return item.get_type_color()
