@tool
extends ItemData
class_name ConsumableData

## Consumable sub-type — set by subclasses in _init(); not @export so .tres
## files cannot accidentally override it.
enum ConsumableType { MEDICINE }
var consumable_type: ConsumableType = ConsumableType.MEDICINE

func _init() -> void:
	item_type = ItemType.CONSUMABLE
