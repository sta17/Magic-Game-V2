@icon("res://Assets/Icons/Pixel-Boy/control/icon_coin.png")
extends Control
class_name VendorUI

#https://interfaceingame.com/screenshots/the-legend-of-zelda-breath-of-the-wild-buy-items/

#https://interfaceingame.com/screenshots/the-witcher-3-wild-hunt-shop-2/

#region Scene node references and Variables

const _SHOP_CARD_SCENE := preload("res://Scenes/UI/shopping_card.tscn")
const _SLOT_SCENE := preload("res://scenes/UI/inventorySlot.tscn")

var _money: ItemData = preload("res://Resources/items/Money.tres")

var _player_inventory: Inventory = null
var _player_equipment: EquipmentManager = null
var _shop_inventory: Inventory = null
var _grid_slots: Array[InventorySlot] = []
var _player: Player = null
var _selected_slot: InventorySlot = null

var _shopping_Card: Array[ShoppingCard] = []

#@onready var _vendor_content: Control         = $VendorContent

@onready var _count_label: Label	= $VendorContent/InvCountLabel
@onready var _grid_root: Control	= $VendorContent/GridRoot
@onready var tooltop: RichTextLabel	= $VendorContent/Tooltip
#@onready var tooltop: Tooltip		= $VendorContent/Tooltip

#endregion

#region Setup

func init(player: Player) -> void:
	_player    = player
	_player_inventory = player.inventory
	_player_equipment = player.equipment

func Show_Vendor(_otherInteracter: NPC, shoppinglist: Array[QuantitySlot] = []) -> void:
	_shop_inventory = Inventory.new()
	_shop_inventory.setList(shoppinglist)
	_shop_inventory.inventory_changed.connect(refresh_grid_slots)

	#_build_grid(_grid_root,_grid_slots,_shop_inventory,InventorySlot.SlotType.ANY)
	#_refresh_grid_slots()
	refresh_Shopping_List()

	#_second_inventory_label.text = interactble_entity.labelText

func hide_vendor() -> void:
	if _shop_inventory:
		_shop_inventory.inventory_changed.disconnect(refresh_grid_slots)
		_shop_inventory = null

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

func getHUD() -> HUD:
	return self.get_parent()

#endregion

#region Refresh

func rebuild(_obj: Variant = null) -> void:
	refresh_grid_slots()

func refresh_grid_slots() -> void:
	_count_label.text = "INVENTORY  (%d / %d)" % [_shop_inventory.items.size(), _shop_inventory.capacity]
	#var visible_items : Array[QuantitySlot] = _shop_inventory.items.filter(func(it: QuantitySlot) -> bool: return not _equipment.is_equipped_wrapper(it))
	var visible_items : Array[QuantitySlot] = _shop_inventory.items
	for i in range(_grid_slots.size()):
		if i < visible_items.size():
			_grid_slots[i].set_item(visible_items[i])
		else:
			_grid_slots[i].set_item(null)

func refresh_Shopping_List() -> void:
	#for n in _grid_root.get_children(): n.queue_free()
	#_shopping_Card.clear()
	var stride  := 100.0
	var left_x  := 0.0
	var y_left:float = 11
	
	for qs: QuantitySlot in _shop_inventory.getList():
		var _SHOP_CARD: ShoppingCard = _SHOP_CARD_SCENE.instantiate()
		_SHOP_CARD.initalise(qs.item)
		_SHOP_CARD.getSlot().slot_clicked.connect(_on_slot_clicked)
		_SHOP_CARD.getSlot().mouse_item_hover.connect(getHUD()._on_slot_mouse_item_hover)
		_grid_root.add_child(_SHOP_CARD)
		_SHOP_CARD.position = Vector2(left_x, y_left)
		_shopping_Card.append(_SHOP_CARD)
		y_left += stride
	pass

#endregion

#region Selection / buttons

func _on_slot_clicked(slot: InventorySlot) -> void:
	_selected_slot = slot
	if slot.item:
		var tempitem:QuantitySlot
		if slot.item is QuantitySlot:
			tempitem = slot.item
		elif slot.item is ItemData:
			tempitem = QuantitySlot.new()
			tempitem.item = slot.item
			tempitem.quantity = 1
		else:
			return
		
		var moneyWrapper: QuantitySlot = QuantitySlot.new()
		moneyWrapper.item = _money
		moneyWrapper.quantity = tempitem.item.value
		if _player_inventory.remove_item(moneyWrapper):
			_player_inventory.add_item(tempitem)
		_clear_selection()

func _clear_selection() -> void:
	_selected_slot    = null

#endregion

#region Drag-and-drop handler (called by InventorySlot._drop_data)

func handle_drop(from_slot: InventorySlot, _to_slot: InventorySlot) -> void:
	var from_item:QuantitySlot = from_slot.itemQuantity
	if from_item == null:
		return
	return
	#SwapSlotsInInventory(from_slot, to_slot,_inventory)
	#_inventory.inventory_changed.emit()
	#_refresh_grid_slots()
	#_clear_selection()

#endregion
