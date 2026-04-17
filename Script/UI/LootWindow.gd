@icon("res://Assets/Icons/Pixel-Boy/control/icon_chest.png")
extends Control
class_name LootWindow

const _SLOT_SCENE := preload("res://scenes/UI/inventorySlot.tscn")

var _inventory: Inventory = null
var _secondary_inventory: Inventory = null
var _grid_slots: Array[InventorySlot] = []
var _selected_slot: InventorySlot = null
var _player: Player = null

@onready var _second_inventory_label: Label = $NinePatchRect/MarginContainer/VBoxContainer/inv_title_text_label
@onready var _grid_root: GridContainer           = $NinePatchRect/MarginContainer/VBoxContainer/GridRoot

#region Setup

func init(player: Player) -> void:
	_player    = player
	_inventory = player.inventory

func _build_grid(_root: Control,_slots: Array[InventorySlot],_l_inventory: Inventory, type: InventorySlot.SlotType) -> void:
	for n in _root.get_children(): n.queue_free()
	_slots.clear()
	var cols := 6
	var step := 66.0  # slot size (60) + gap (6)
	for i in range(_l_inventory.capacity):
		var slot := _SLOT_SCENE.instantiate() as InventorySlot
		slot.slot_type = type
		@warning_ignore("integer_division")
		slot.position  = Vector2((i % cols) * step, (i / cols) * step)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.mouse_item_hover.connect((self.get_parent() as HUD)._on_slot_mouse_item_hover)
		slot.index = i
		_root.add_child(slot)
		_slots.append(slot)

#endregion

#region Box Inventory

func ShowHide_Inventory_Box(interactble_entity: Box) -> void:
	# make visible
	_grid_root.visible = not _grid_root.visible
	if _grid_root.visible:
		_secondary_inventory = interactble_entity.get_inventory()
		_second_inventory_label.text = interactble_entity.labelText
		_secondary_inventory.inventory_changed.connect(_refresh_grid_slots)
		# fill in new slots
		_build_grid(_grid_root,_grid_slots,_secondary_inventory,InventorySlot.SlotType.SECONDARY)
		_refresh_grid_slots()
		# set name
		_second_inventory_label.text = interactble_entity.labelText
	else:
		_secondary_inventory.inventory_changed.disconnect(_refresh_grid_slots)
		_secondary_inventory = null

func _refresh_grid_slots() -> void:
	#_count_label.text = "INVENTORY  (%d / %d)" % [_secondary_inventory.items.size(), _secondary_inventory.capacity]
	var visible_items : Array[QuantitySlot] = _secondary_inventory.items
	for i in range(_grid_slots.size()):
		if i < visible_items.size():
			_grid_slots[i].set_item(visible_items[i])
		else:
			_grid_slots[i].set_item(null)

#endregion

#region Selection / buttons

func _on_slot_clicked(slot: InventorySlot) -> void:
	_selected_slot = slot
	if slot.item:
		handle_drop(slot, null)

func _on_use_pressed() -> void:
	if _selected_slot and _selected_slot.itemQuantity and _player:
		_player.use_item(_selected_slot.itemQuantity)
	_clear_selection()

func _on_drop_pressed() -> void:
	if _selected_slot and _selected_slot.item:
		_inventory.remove_item(_selected_slot.itemQuantity)
	_clear_selection()

func _clear_selection() -> void:
	_selected_slot    = null

#endregion

#region Drag-and-drop handler (called by InventorySlot._drop_data)

func handle_drop(from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	var from_item:QuantitySlot = from_slot.itemQuantity
	if from_item == null:
		return

	elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY or to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
		if to_slot == null:
			_inventory.transferBetweenInventoriesSimple(from_slot,_secondary_inventory,_inventory)
		elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY and to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
			_inventory.SwapSlotsInInventory(from_slot, to_slot,_secondary_inventory)
		else:
			var to_item:QuantitySlot = to_slot.itemQuantity
		
			if from_slot.slot_type == InventorySlot.SlotType.SECONDARY:
				if to_item == null:
					_inventory.transferBetweenInventories(from_slot, to_slot,_secondary_inventory,_inventory)
				else:
					_inventory.SwapSlotsBetweenInventories(from_slot, to_slot,_inventory,_secondary_inventory)
			elif to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
				if to_item == null:
					_inventory.transferBetweenInventories(from_slot, to_slot,_inventory,_secondary_inventory)
				else:
					_inventory.SwapSlotsBetweenInventories(from_slot, to_slot,_inventory,_secondary_inventory)
			_secondary_inventory.inventory_changed.emit()
			_inventory.inventory_changed.emit()
	else:
		_inventory.SwapSlotsInInventory(from_slot, to_slot,_inventory)

	_refresh_grid_slots()
	_clear_selection()

#endregion
