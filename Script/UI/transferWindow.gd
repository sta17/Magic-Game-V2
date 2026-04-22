@icon("res://Assets/Icons/Pixel-Boy/control/icon_bag.png")
extends Control
class_name TransferWindow

signal mouse_slot_hover(status: bool, currentSlot:Slot)

const _SLOT_SCENE := preload("res://scenes/UI/inventorySlot.tscn")

var _inventory: Inventory = null
var _secondary_inventory: Inventory = null
var _grid_slots: Array[InventorySlot] = []
var _grid_slots2: Array[InventorySlot] = []
var _hotbar: HotbarUI = null
var _selected_slot: InventorySlot = null

#region Scene node references

@onready var _player_inventory_label: Label			= $InvCountLabel
@onready var _grid_root: Control				= $GridRoot
@onready var _grid2_root: Control				= $GridRoot2
@onready var _second_inventory_label: Label		= $InvCountLabel2

@onready var _use_btn: Button					= $UseBtn
@onready var _drop_btn: Button					= $DropBtn

@onready var vendorContent: GridContainer		= $VendorContent

#endregion

#region Setup

func init(inventory: Inventory, h: HotbarUI) -> void:
	_inventory = inventory
	_hotbar = h

	_inventory.inventory_changed.connect(_rebuild)

	_use_btn.pressed.connect(_on_use_pressed)
	_drop_btn.pressed.connect(_on_drop_pressed)
	_use_btn.visible  = false
	_drop_btn.visible = false

	_build_grid(_grid_root,_grid_slots,_inventory,InventorySlot.SlotType.ANY)
	_refresh_grid_slots()

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
		slot.mouse_item_hover.connect(_on_slot_mouse_item_hover)
		slot.index = i
		_root.add_child(slot)
		_slots.append(slot)

#endregion

#region Box Inventory

func ShowHide_Inventory_Box(interactble_entity: Box) -> void:
	# make visible
	_second_inventory_label.visible = not _second_inventory_label.visible
	_grid2_root.visible = not _grid2_root.visible
	if _grid2_root.visible:
		_secondary_inventory = interactble_entity.get_inventory()
		_secondary_inventory.inventory_changed.connect(_rebuild)
		# fill in new slots
		_build_grid(_grid2_root,_grid_slots2,_secondary_inventory,InventorySlot.SlotType.SECONDARY)
		_refresh_grid_slots2()
		# set name
		_second_inventory_label.text = interactble_entity.labelText
	else:
		_secondary_inventory.inventory_changed.disconnect(_rebuild)
		_secondary_inventory = null

#endregion

#region Refresh

func _rebuild(_obj: Variant = null) -> void:
	_refresh_grid_slots()
	if self.visible == true:
		_refresh_grid_slots2()

func _refresh_grid_slots() -> void:
	_player_inventory_label.text = "INVENTORY  (%d / %d)" % [_inventory.items.size(), _inventory.capacity]
	var visible_items : Array[QuantitySlot] = _inventory.items
	for i in range(_grid_slots.size()):
		if i < visible_items.size():
			_grid_slots[i].set_item(visible_items[i])
		else:
			_grid_slots[i].set_item(null)

func _refresh_grid_slots2() -> void:
	_player_inventory_label.text = "INVENTORY  (%d / %d)" % [_secondary_inventory.items.size(), _secondary_inventory.capacity]
	var visible_items : Array[QuantitySlot] = _secondary_inventory.items
	for i in range(_grid_slots2.size()):
		if i < visible_items.size():
			_grid_slots2[i].set_item(visible_items[i])
		else:
			_grid_slots2[i].set_item(null)

#endregion

#region Selection / buttons

func _on_slot_clicked(slot: InventorySlot) -> void:
	_selected_slot = slot

func _on_use_pressed() -> void:
	if _selected_slot and _selected_slot.itemQuantity:
		_inventory.use_item(_selected_slot.itemQuantity)
	_clear_selection()

func _on_drop_pressed() -> void:
	if _selected_slot and _selected_slot.item:
		var itemQ: QuantitySlot = _selected_slot.itemQuantity
		
		if _inventory.remove_item(itemQ):
			_inventory.drop_item(itemQ)
	_clear_selection()

func _clear_selection() -> void:
	_selected_slot    = null
	_use_btn.visible  = false
	_drop_btn.visible = false

#endregion

#region Drag-and-drop handler (called by InventorySlot._drop_data)

func handle_drop(from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	var from_item:QuantitySlot = from_slot.itemQuantity
	if from_item == null:
		return

	if from_slot.slot_type == InventorySlot.SlotType.HOTBAR:
		if _hotbar:
			_hotbar.unassign_slot(from_slot)
	elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY or to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
		var to_item:QuantitySlot = to_slot.itemQuantity
		if from_slot.slot_type == InventorySlot.SlotType.SECONDARY and to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
			_inventory.SwapSlotsInInventory(from_slot, to_slot,_secondary_inventory)
		elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY:
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

#region Slot type helpers

func _on_slot_mouse_item_hover(currentSlot: Slot, status: bool) -> void:
	mouse_slot_hover.emit(currentSlot,status)

#endregion
