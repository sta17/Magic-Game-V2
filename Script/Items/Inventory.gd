@icon("res://Assets/Icons/Pixel-Boy/node/icon_money_bag.png")
extends Resource
class_name Inventory

signal inventory_changed

@export var capacity: int = 20
@export var items: Array[QuantitySlot] = []

func init() -> void:
	for i in range(0,capacity):
		items.append(null)

#region Add

func add_item(item: QuantitySlot) -> bool:
	if is_empty() or not is_full():
		return add_item_quantity(item)
	return false

func add_item_simple(item: QuantitySlot) -> bool:
	if is_empty() or not is_full():
		append(item)
		inventory_changed.emit()
		return true
	return false

func add_quantity(item: QuantitySlot, idx:int) -> bool:
	if (items[idx].quantity + item.quantity) <= items[idx].item.max_stack:
		items[idx].quantity = items[idx].quantity + item.quantity
		inventory_changed.emit()
		return true
	return false

func add_item_quantity(item: QuantitySlot, startIdx: int = 0) -> bool:
	if item.item.stackable:
		var idx: int = findItemFrom(item,startIdx)
		if idx == -1:
			return add_item_simple(item)
		else:
			if add_quantity(item,idx):
				return true
			else:
				if items[idx].item.max_stack == items[idx].quantity:
					return add_item_quantity(item, idx+1)
				else:
					var excessAmount: int = items[idx].item.max_stack - items[idx].quantity
				
					var excessQuantity: QuantitySlot = QuantitySlot.new()
					excessQuantity.item = item.item
					excessQuantity.quantity = excessAmount
					if add_item_quantity(excessQuantity, idx+1):
						item.quantity = item.quantity - excessAmount
						add_quantity(item,idx)
						inventory_changed.emit()
						return true
					else:
						return false
	return add_item_simple(item)

func add_item_at_index(quantityCounter : QuantitySlot,add_index: int) -> bool:
	items[add_index] = quantityCounter
	return true

#endregion

#region Remove

func remove_item(item: QuantitySlot) -> bool:
	var idx: int = findItem(item)
	if idx == -1:
		return false
	return remove_item_quantity_at_index(item,idx)

func remove_item_at_index(remove_index:int) -> bool:
	items.remove_at(remove_index)
	inventory_changed.emit()
	return true

func remove_item_quantity_at_index(quantityCounter : QuantitySlot,remove_index: int) -> bool:
	if quantityCounter.item.stackable:
		if quantityCounter.quantity == items[remove_index].quantity:
			return remove_item_at_index(remove_index)
		elif quantityCounter.quantity < items[remove_index].quantity:
			items[remove_index].quantity = items[remove_index].quantity - quantityCounter.quantity
			inventory_changed.emit()
			return true
		else:
			return false
	else:
		return remove_item_at_index(remove_index)

#endregion

#region Safety Checks and Misc

func findItem(item: QuantitySlot) -> int:
	for i in range(items.size()):
		if items[i] != null:
			if items[i].item != null:
				if items[i].item == item.item:
					return i
	return -1

func findItemFrom(item: QuantitySlot, startIdx: int = 0) -> int:
	if startIdx == items.size():
		return -1
	for i in range(startIdx,items.size()):
		if items[i] != null:
			if items[i].item != null:
				if items[i].item == item.item:
					return i
	return -1

func is_full() -> bool:
	var empty: int = capacity - EmptySlots()
	var b: bool = empty >= capacity
	return b

func is_empty() -> bool:
	var empty: int = capacity - EmptySlots()
	var b: bool = empty == capacity
	return b

func EmptySlots() -> int:
	return items.filter(func(it: QuantitySlot) -> bool: return isSlotEmpty(it)).size()

func isSlotEmpty(slot: QuantitySlot) -> bool:
	return slot == null

func get_items_of_type(type: ItemData.ItemType) -> Array:
	var result: Array = []
	for item in items:
		if item != null:
			if item.item.item_type == type:
				result.append(item)
	return result

func has_item(search_name: String) -> bool:
	for item in items:
		if item.item.item_name == search_name:
			return true
	return false

func setList(newitems: Array[QuantitySlot]) -> void:
	items = newitems

func getList() -> Array[QuantitySlot]:
	return items

func append(item: QuantitySlot) -> bool:
	for i in range(0,items.size()):
		if items[i] == null:
			items[i] = item
			return true
	return false
	

#endregion

#region Swap Between Inventories

func SwapSlotsInInventory(from_slot: InventorySlot, to_slot: InventorySlot,inv:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	var to_item:QuantitySlot = to_slot.itemQuantity
	if inv.add_item_at_index(from_item,to_slot.index):
		if inv.add_item_at_index(to_item,from_slot.index):
			inv.inventory_changed.emit()
		else:
			inv.remove_item_quantity(to_item)
	return true

func SwapSlotsBetweenInventories(from_slot: InventorySlot, to_slot: InventorySlot,inv1:Inventory,inv2:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	var to_item:QuantitySlot = to_slot.itemQuantity
	if inv1.add_item_at_index(to_item,to_slot.index):
		if inv2.add_item_at_index(from_item,from_slot.index):
			inv2.inventory_changed.emit()
			inv1.inventory_changed.emit()
		else:
			inv1.remove_item_quantity(to_item)
	return true

func transferBetweenInventories(from_slot: InventorySlot, to_slot: InventorySlot,inv1:Inventory,inv2:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	if inv2.add_item_at_index(from_item,to_slot.index):
		inv1.remove_item_quantity(from_item)
		inv2.inventory_changed.emit()
		inv1.inventory_changed.emit()
		return true
	return false

func transferBetweenInventoriesSimple(from_slot: InventorySlot,inv1:Inventory,inv2:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	if inv2.add_item(from_item):
		inv1.remove_item_at_index(from_slot.index)
		inv2.inventory_changed.emit()
		inv1.inventory_changed.emit()
		return true
	return false

#endregion
