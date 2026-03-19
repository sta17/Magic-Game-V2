extends Node
class_name Inventory

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal inventory_changed

@export var capacity: int = 20

var items: Array[ItemData] = []

func add_item(item: ItemData) -> bool:
	if items.size() >= capacity:
		return false
	# Merge stackable items
	if item.stackable:
		for existing in items:
			if existing.item_name == item.item_name and existing.quantity < existing.max_stack:
				existing.quantity = min(existing.quantity + item.quantity, existing.max_stack)
				item_added.emit(item)
				inventory_changed.emit()
				return true
	items.append(item)
	item_added.emit(item)
	inventory_changed.emit()
	return true

func remove_item(item: ItemData) -> bool:
	var idx = items.find(item)
	if idx == -1:
		return false
	items.remove_at(idx)
	item_removed.emit(item)
	inventory_changed.emit()
	return true

func is_full() -> bool:
	return items.size() >= capacity

func get_items_of_type(type: ItemData.ItemType) -> Array:
	var result: Array = []
	for item in items:
		if item.item_type == type:
			result.append(item)
	return result

func has_item(search_name: String) -> bool:
	for item in items:
		if item.item_name == search_name:
			return true
	return false
