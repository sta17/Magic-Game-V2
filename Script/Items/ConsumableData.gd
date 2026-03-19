@tool
extends ItemData
class_name ConsumableData

## Consumable sub-type — set by subclasses in _init(); not @export so .tres
## files cannot accidentally override it.
enum ConsumableType { MEDICINE }
var consumable_type: ConsumableType = ConsumableType.MEDICINE

func _init() -> void:
	item_type = ItemType.CONSUMABLE

## Returns the icon — inspector override > exported PNG > missing-icon placeholder.
func get_icon() -> Texture2D:
	if icon:
		return icon
	# Derive PNG name from consumable_type so it works even before item_name is set.
	var png_name: String
	match consumable_type:
		ConsumableType.MEDICINE: png_name = "medkit"
	var png_path := "res://resources/icons/" + png_name + ".png"
	if ResourceLoader.exists(png_path):
		return ResourceLoader.load(png_path) as Texture2D
	return null
