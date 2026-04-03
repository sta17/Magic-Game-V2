extends Resource
class_name Inventory

signal inventory_changed

@export var capacity: int = 20

@export var items: Array[QuantitySlot] = []

func add_item(item: ItemData) -> bool:
	if items.size() >= capacity:
		return false
	# Merge stackable items
	if item.stackable:
		for existing in items:
			if existing.item_name == item.item_name and existing.quantity < existing.max_stack:
				existing.quantity = min(existing.quantity + item.quantity, existing.max_stack)
				inventory_changed.emit()
				return true
	items.append(item)
	inventory_changed.emit()
	return true

func add_item_with_quantity(quantityCounter : QuantitySlot) -> bool:
	var item: ItemData = quantityCounter.item
	if items.size() >= capacity:
		return false
	# Merge stackable items
	if quantityCounter.item.stackable:
		for existing in items:
			if existing.getName() == item.getName() and quantityCounter.quantity < existing.item.max_stack:
				if (existing.quantity + quantityCounter.quantity) > existing.item.max_stack:
					items.append(quantityCounter)
				else:
					existing.quantity = existing.quantity + quantityCounter.quantity
				inventory_changed.emit()
				return true
	items.append(quantityCounter)
	inventory_changed.emit()
	return true

func add_item_with_quantity_at_index(quantityCounter : QuantitySlot,add_index: int) -> bool:
	var item: ItemData = quantityCounter.item
	if items.size() >= capacity:
		return false
	# Merge stackable items
	if quantityCounter.item.stackable:
		for existing in items:
			if existing.getName() == item.getName() and quantityCounter.quantity < existing.item.max_stack:
				if (existing.quantity + quantityCounter.quantity) > existing.item.max_stack:
					if items[add_index] != null:
						return false
					else:
						items[add_index] = quantityCounter
						#items.append(quantityCounter)
				else:
					existing.quantity = existing.quantity + quantityCounter.quantity
				inventory_changed.emit()
				return true
	items.append(quantityCounter)
	inventory_changed.emit()
	return true

func remove_item_quantity(item: QuantitySlot) -> bool:
	var idx: int = items.find(item)
	if idx == -1:
		return false
	return remove_item_quantity_at_index(idx)

func remove_item_quantity_at_index(remove_index:int) -> bool:
	items.remove_at(remove_index)
	inventory_changed.emit()
	return true

func remove_item(item: ItemData) -> bool:
	var idx: int = items.find(item)
	if idx == -1:
		return false
	items.remove_at(idx)
	inventory_changed.emit()
	return true

func is_full() -> bool:
	return items.size() >= capacity

func get_items_of_type(type: ItemData.ItemType) -> Array:
	var result: Array = []
	for item in items:
		if item.item.item_type == type:
			result.append(item)
	return result

func has_item(search_name: String) -> bool:
	for item in items:
		if item.item.item_name == search_name:
			return true
	return false
