@icon("res://Assets/Icons/Mine/UI.png")
extends Control
class_name InventoryUI

const _SLOT_SCENE := preload("res://scenes/UI/inventorySlot.tscn")
const _ACT_SCENE := preload("res://Scenes/UI/act_abi_label.tscn")
const _PAS_SCENE := preload("res://Scenes/UI/pas_abi_label.tscn")
const _PAS_HOT_SCENE := preload("res://Scenes/UI/PassiveHotbar.tscn")
const _ABI_CARD_SCENE := preload("res://Scenes/UI/ability_card.tscn")

var _inventory: Inventory = null
var _secondary_inventory: Inventory = null
var _equipment: EquipmentManager = null
var _ability_list: AbilityList = null
var _grid_slots: Array[InventorySlot] = []
var _grid_slots2: Array[InventorySlot] = []
var _player: Player = null
var _hotbar: HotbarUI = null
var _selected_slot: InventorySlot = null
var _active_tab: int = 0

#region Scene node references

@onready var _tab_inv_btn: Button          = $TabInvBtn
@onready var _tab_abi_btn: Button          = $TabAbiBtn
@onready var _inv_content: Control         = $InvContent
@onready var _abi_content: Control         = $AbiContent

@onready var _eq_weapon_slot: InventorySlot    = $InvContent/WpnSlot
@onready var _eq_armor_slot: InventorySlot     = $InvContent/ArmSlot
@onready var _eq_accessory_slot: InventorySlot = $InvContent/AccSlot
@onready var _count_label: Label           = $InvContent/InvCountLabel
@onready var _grid_root: Control           = $InvContent/GridRoot
@onready var _use_btn: Button              = $InvContent/UseBtn
@onready var _drop_btn: Button             = $InvContent/DropBtn

@onready var _second_inventory_label: Label = $InvContent/InvCountLabel2
@onready var _grid2_root: Control           = $InvContent/GridRoot2

@onready var passive_hotbar: PassiveHotbar = $AbiContent/AbiScroll/PassiveHotbar
@onready var _abilities_container: Control = $AbiContent/AbiScroll/AbilitiesContainer

#endregion

#region Setup

func init(player: Player) -> void:
	_player    = player
	_inventory = player.inventory
	_equipment = player.equipment

	_inventory.inventory_changed.connect(_rebuild)
	_equipment.weapon_equipped.connect(_rebuild)
	_equipment.armor_equipped.connect(_rebuild)
	_equipment.accessory_equipped.connect(_rebuild)
	_equipment.slot_cleared.connect(_rebuild)

	_tab_inv_btn.pressed.connect(func() -> void: _set_tab(0))
	_tab_abi_btn.pressed.connect(func() -> void: _set_tab(1))

	_eq_weapon_slot.slot_clicked.connect(_on_slot_clicked)
	_eq_armor_slot.slot_clicked.connect(_on_slot_clicked)
	_eq_accessory_slot.slot_clicked.connect(_on_slot_clicked)

	_use_btn.pressed.connect(_on_use_pressed)
	_drop_btn.pressed.connect(_on_drop_pressed)
	_use_btn.visible  = false
	_drop_btn.visible = false

	_ability_list = player.ability_list
	_ability_list.changed.connect(_rebuild_abilities)

	_build_grid(_grid_root,_grid_slots,_inventory,InventorySlot.SlotType.ANY)
	_rebuild_abilities()
	_set_tab(0)
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
		slot.mouse_item_hover.connect((self.get_parent() as HUD)._on_slot_mouse_item_hover)
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
	pass
	

#endregion

#region Bonuses

func get_passive_speed_bonus() -> float:
	return passive_hotbar.get_passive_speed_bonus() if passive_hotbar else 0.0

func get_passive_damage_bonus() -> float:
	return passive_hotbar.get_passive_damage_bonus() if passive_hotbar else 0.0

func get_passive_health_regen() -> float:
	return passive_hotbar.get_passive_health_regen() if passive_hotbar else 0.0

#endregion

#region Hotbars and Ability

func auto_add_passive(ability: AbilityData) -> void:
	if passive_hotbar:
		passive_hotbar.auto_add(ability)

func auto_remove_passive(ability: AbilityData) -> void:
	if passive_hotbar:
		passive_hotbar.remove_ability_ref(ability)

func set_hotbar(h: HotbarUI) -> void:
	_hotbar = h

#endregion

#region Tab switching

func _set_tab(idx: int) -> void:
	_active_tab          = idx
	_inv_content.visible = (idx == 0)
	_abi_content.visible = (idx == 1)
	var gold := Color(1.0, 0.84, 0.0)
	var grey := Color(0.5, 0.5, 0.5)
	_tab_inv_btn.add_theme_color_override("font_color", gold if idx == 0 else grey)
	_tab_abi_btn.add_theme_color_override("font_color", gold if idx == 1 else grey)

#endregion

#region Refresh

func _rebuild(_obj: Variant = null) -> void:
	_refresh_grid_slots()
	_refresh_eq_slots()
	if _grid2_root.visible == true:
		_refresh_grid_slots2()

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

func _refresh_grid_slots2() -> void:
	_count_label.text = "INVENTORY  (%d / %d)" % [_secondary_inventory.items.size(), _secondary_inventory.capacity]
	#var visible_items : Array[QuantitySlot] = _secondary_inventory.items.filter(func(it: QuantitySlot) -> bool: return not _equipment.is_equipped_wrapper(it))
	var visible_items : Array[QuantitySlot] = _secondary_inventory.items
	for i in range(_grid_slots2.size()):
		if i < visible_items.size():
			_grid_slots2[i].set_item(visible_items[i])
		else:
			_grid_slots2[i].set_item(null)

func _rebuild_abilities() -> void:
	# Clear dynamic nodes but keep the persistent passive_hotbar
	for child in _abilities_container.get_children():
		child.queue_free()

	var stride  := 100.0
	var col_w   := 365.0
	var col_gap := 20.0
	var left_x  := 0.0
	var right_x := col_w + col_gap

	var active_abs  : Array[AbilityData] = _ability_list.abilities.filter(func(a: AbilityData) -> bool: return not a.is_passive)
	var passive_abs : Array[AbilityData] = _ability_list.abilities.filter(func(a: AbilityData) -> bool: return a.is_passive)
	
	var y_left:float = 11
	for ab: AbilityData in active_abs:
		var _ABI_CARD := _ABI_CARD_SCENE.instantiate()
		_ABI_CARD.initalise(ab)
		_ABI_CARD.position = Vector2(left_x, y_left)
		_abilities_container.add_child(_ABI_CARD)
		y_left += stride
	if active_abs.is_empty():
		y_left += 30.0
	
	var y_right:float = 90.0

	for ab:AbilityData in passive_abs:
		var _ABI_CARD : AbilityCard = _ABI_CARD_SCENE.instantiate()
		_ABI_CARD.initalise(ab)
		_ABI_CARD.position = Vector2(right_x, y_right)
		_abilities_container.add_child(_ABI_CARD)
		y_right += stride

	_abilities_container.custom_minimum_size = Vector2(0, 0)

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
		var item: ItemData = _selected_slot.item as ItemData
		if _equipment.is_equipped(item):
			match item.item_type:
				ItemData.ItemType.WEAPON:    _equipment.unequip_weapon()
				ItemData.ItemType.ARMOR:     _equipment.unequip_armor()
				ItemData.ItemType.ACCESSORY: _equipment.unequip_accessory()
		_inventory.remove_item(item)
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
		_equipment.equip_item(from_item)
	elif from_is_eq:
		match _get_eq_type(from_slot):
			InventorySlot.SlotType.WEAPON:    _equipment.unequip_weapon()
			InventorySlot.SlotType.ARMOR:     _equipment.unequip_armor()
			InventorySlot.SlotType.ACCESSORY: _equipment.unequip_accessory()
	elif from_slot.slot_type == InventorySlot.SlotType.HOTBAR:
		if _hotbar:
			_hotbar.unassign_slot(from_slot)
	elif from_slot.slot_type == InventorySlot.SlotType.PASSIVE_HOTBAR:
		if passive_hotbar:
			passive_hotbar.unassign_slot(from_slot)
	elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY or to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
		var to_item:QuantitySlot = to_slot.itemQuantity
		if from_slot.slot_type == InventorySlot.SlotType.SECONDARY and to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
			_inventory.SwapSlotsInInventory(from_slot, to_slot,_secondary_inventory)
		elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY:
			if to_item == null:
				_inventory.add_single_Slot(from_slot, to_slot,_secondary_inventory,_inventory)
			else:
				_inventory.SwapSlots(from_slot, to_slot,_inventory,_secondary_inventory)
		elif to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
			if to_item == null:
				_inventory.add_single_Slot(from_slot, to_slot,_inventory,_secondary_inventory)
			else:
				_inventory.SwapSlots(from_slot, to_slot,_inventory,_secondary_inventory)
		_secondary_inventory.inventory_changed.emit()
		_inventory.inventory_changed.emit()
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

#endregion
