@icon("res://Assets/Icons/Pixel-Boy/control/icon_bag.png")
extends Control
class_name InvWindow

const _SLOT_SCENE := preload("res://scenes/UI/inventorySlot.tscn")

var _inventory: Inventory = null
var _equipment: EquipmentManager = null
var _grid_slots: Array[InventorySlot] = []
var _player: Player = null
var _hotbar: HotbarUI = null
var _selected_slot: InventorySlot = null
var _invPanel: InventoryUI = null

#region Scene node references

@onready var _eq_weapon_slot: InventorySlot		= $WpnSlot
@onready var _eq_armor_slot: InventorySlot		= $ArmSlot
@onready var _eq_accessory_slot: InventorySlot	= $AccSlot
@onready var _count_label: Label				= $InvCountLabel
@onready var _grid_root: Control				= $GridRoot
@onready var _use_btn: Button					= $UseBtn
@onready var _drop_btn: Button					= $DropBtn

#endregion

#region Setup

func init(player: Player, invPanel: InventoryUI) -> void:
	_player    = player
	_inventory = player.inventory
	_equipment = player.equipment
	_invPanel = invPanel

	_inventory.inventory_changed.connect(_rebuild)
	_equipment.weapon_equipped.connect(_rebuild)
	_equipment.armor_equipped.connect(_rebuild)
	_equipment.accessory_equipped.connect(_rebuild)
	_equipment.slot_cleared.connect(_rebuild)

	_eq_weapon_slot.slot_clicked.connect(_on_slot_clicked)
	_eq_armor_slot.slot_clicked.connect(_on_slot_clicked)
	_eq_accessory_slot.slot_clicked.connect(_on_slot_clicked)

	_use_btn.pressed.connect(_on_use_pressed)
	_drop_btn.pressed.connect(_on_drop_pressed)
	_use_btn.visible  = false
	_drop_btn.visible = false

	_build_grid(_grid_root,_grid_slots,_inventory,InventorySlot.SlotType.ANY)
	_refresh_eq_slots()
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
		slot.mouse_item_hover.connect(getHUD()._on_slot_mouse_item_hover)
		slot.index = i
		_root.add_child(slot)
		_slots.append(slot)

#endregion

#region Hotbars and Ability

func set_hotbar(h: HotbarUI) -> void:
	_hotbar = h

#endregion

#region Refresh

func _rebuild(_obj: Variant = null) -> void:
	_refresh_grid_slots()
	_refresh_eq_slots()

func _refresh_eq_slots() -> void:
	_eq_weapon_slot.set_item(_equipment.equipped_weapon_wrapper,true)
	_eq_armor_slot.set_item(_equipment.equipped_armor_wrapper,true)
	_eq_accessory_slot.set_item(_equipment.equipped_accessory_wrapper,true)

func _refresh_grid_slots() -> void:
	_count_label.text = "INVENTORY  (%d / %d)" % [_inventory.items.size(), _inventory.capacity]
	var visible_items : Array[QuantitySlot] = _inventory.items.filter(func(it: QuantitySlot) -> bool: return not _equipment.is_equipped_wrapper(it))
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
		var is_eq := _is_eq_slot(slot)
		
		var tempitem:Slot
		if slot.item is QuantitySlot:
			tempitem = slot.item.item
		else:
			tempitem = slot.item
		_use_btn.visible  = not is_eq and tempitem.item_type == ItemData.ItemType.CONSUMABLE
		_drop_btn.visible = not is_eq
	else:
		_use_btn.visible  = false
		_drop_btn.visible = false

func _on_use_pressed() -> void:
	if _selected_slot and _selected_slot.itemQuantity and _player:
		_player.use_item(_selected_slot.itemQuantity)
	_clear_selection()

func _on_drop_pressed() -> void:
	if _selected_slot and _selected_slot.item:
		var itemQ: QuantitySlot = _selected_slot.itemQuantity
		
		if _equipment.is_equipped_wrapper(itemQ):
			match itemQ.item.item_type:
				ItemData.ItemType.WEAPON:    _equipment.unequip_weapon()
				ItemData.ItemType.ARMOR:     _equipment.unequip_armor()
				ItemData.ItemType.ACCESSORY: _equipment.unequip_accessory()
		if _inventory.remove_item(itemQ):
			_player.drop_item(itemQ)
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

	var from_is_eq := _is_eq_slot(from_slot)
	var to_is_eq   := _is_eq_slot(to_slot)

	if to_is_eq:
		match from_item.item.item_type:
			ItemData.ItemType.WEAPON: _equipment.equip_itemNew(from_slot,to_slot,_inventory)
			ItemData.ItemType.ARMOR:_equipment.equip_itemNew(from_slot,to_slot,_inventory)
			ItemData.ItemType.ACCESSORY: _equipment.equip_itemNew(from_slot,to_slot,_inventory)
	elif from_is_eq:
		match _get_eq_type(from_slot):
			InventorySlot.SlotType.WEAPON:    _equipment.unequip_itemNew(from_slot, to_slot,_inventory)
			InventorySlot.SlotType.ARMOR:     _equipment.unequip_itemNew(from_slot, to_slot,_inventory)
			InventorySlot.SlotType.ACCESSORY: _equipment.unequip_itemNew(from_slot, to_slot,_inventory)
	elif from_slot.slot_type == InventorySlot.SlotType.HOTBAR:
		if _hotbar:
			_hotbar.unassign_slot(from_slot)
	elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY or to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
		return
	else:
		_inventory.SwapSlotsInInventory(from_slot, to_slot,_inventory)

	_refresh_eq_slots()
	_refresh_grid_slots()
	_clear_selection()

#endregion

#region Slot type helpers

func _is_eq_slot(slot: InventorySlot) -> bool:
	return slot == _eq_weapon_slot or slot == _eq_armor_slot or slot == _eq_accessory_slot

func _get_eq_type(slot: InventorySlot) -> InventorySlot.SlotType:
	if slot == _eq_weapon_slot: return InventorySlot.SlotType.WEAPON
	if slot == _eq_armor_slot:  return InventorySlot.SlotType.ARMOR
	return InventorySlot.SlotType.ACCESSORY

func getHUD() -> HUD:
	return _invPanel.getHUD()

#endregion
