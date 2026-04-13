extends Resource
class_name Inventory

signal inventory_changed

@export var capacity: int = 20
@export var items: Array[QuantitySlot] = []

#region Add

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
		for i in items.size():
			var existing: QuantitySlot = items[i]
			if existing == null:
				items[i] = quantityCounter
				inventory_changed.emit()
				return true
			elif existing.getName() == item.getName() and quantityCounter.quantity < existing.item.max_stack:
				if (existing.quantity + quantityCounter.quantity) > existing.item.max_stack:
					if items[add_index] != null:
						return false
					else:
						items[add_index] = quantityCounter
				else:
					existing.quantity = existing.quantity + quantityCounter.quantity
				inventory_changed.emit()
				return true
	items.append(quantityCounter)
	inventory_changed.emit()
	return true

#endregion

#region Remove

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

#endregion

#region Safety Checks and Misc

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

#endregion

#region Swap Between Inventories

func SwapSlotsInInventory(from_slot: InventorySlot, to_slot: InventorySlot,inv:Inventory) -> bool:
	# Inventory ↔ Inventory swap (reorder by item reference, not slot index)
	var fi := inv.items.find(from_slot.itemQuantity)
	var ti := inv.items.find(to_slot.itemQuantity)
	if fi != -1 and ti != -1:
		var tmp        := inv.items[fi]
		inv.items[fi] = inv.items[ti]
		inv.items[ti] = tmp
		inv.inventory_changed.emit()
		return true
	return false

func SwapSlots(from_slot: InventorySlot, to_slot: InventorySlot,inv1:Inventory,inv2:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	var to_item:QuantitySlot = to_slot.itemQuantity
	if inv1.add_item_with_quantity_at_index(to_item,to_slot.index):
		if inv2.add_item_with_quantity_at_index(from_item,from_slot.index):
			inv2.remove_item_quantity(from_item)
			inv1.remove_item_quantity(to_item)
			inv2.inventory_changed.emit()
			inv1.inventory_changed.emit()
		else:
			inv1.remove_item_quantity(to_item)
	return true

func add_single_Slot(from_slot: InventorySlot, to_slot: InventorySlot,inv1:Inventory,inv2:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	if inv2.add_item_with_quantity_at_index(from_item,to_slot.index):
		inv1.remove_item_quantity(from_item)
		inv2.inventory_changed.emit()
		inv1.inventory_changed.emit()
		return true
	return false

#endregion
