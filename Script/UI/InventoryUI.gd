@icon("res://Assets/Icons/Pixel-Boy/control/icon_bag.png")
extends Control
class_name InventoryUI

var _player: Player = null
var _hotbar: HotbarUI = null
var _selected_slot: InventorySlot = null
var _active_tab: int = 0

#region Scene node references

@onready var _transfer_window: TransferWindow = $MarginContainer/TransferContent
@onready var _inv_window: InvWindow 		= $MarginContainer/InvContent
@onready var _abi_window: AbilityWindow 	= $MarginContainer/AbiContent

@onready var _tab_inv_btn: Button			= $TabInvBtn
@onready var _tab_abi_btn: Button			= $TabAbiBtn
@onready var _tab_stats_btn: Button			= $TabStatsBtn

@export var tabList: Array[Control] = []

#endregion

#region Setup

func init(player: Player) -> void:
	_player    = player
	_transfer_window.init(player,self)
	_inv_window.init(player,self)
	_abi_window.init(player,self)

	_tab_inv_btn.pressed.connect(func() -> void: _set_tab(0))
	_tab_abi_btn.pressed.connect(func() -> void: _set_tab(1))
	_tab_stats_btn.pressed.connect(func() -> void: _set_tab(2))

	for i in range(tabList.size()):
		tabList[i].visible = false

	_set_tab(0)

#endregion

#region Box Inventory

func ShowHide_Inventory_Box(interactble_entity: Box) -> void:
	_transfer_window.ShowHide_Inventory_Box(interactble_entity)

#endregion

#region Bonuses

func get_passive_speed_bonus() -> float:
	return _abi_window.get_passive_speed_bonus()

func get_passive_damage_bonus() -> float:
	return _abi_window.get_passive_damage_bonus()

func get_passive_health_regen() -> float:
	return _abi_window.get_passive_health_regen()

#endregion

#region Hotbars and Ability

func auto_add_passive(ability: AbilityData) -> void:
	_abi_window.auto_add_passive(ability)

func auto_remove_passive(ability: AbilityData) -> void:
	_abi_window.auto_remove_passive(ability)

func set_hotbar(h: HotbarUI) -> void:
	_hotbar = h
	_transfer_window.set_hotbar(_hotbar)
	_inv_window.set_hotbar(_hotbar)
	_abi_window.set_hotbar(_hotbar)

#endregion

#region Tab switching

func _set_tab(newIdx: int) -> void:
	var gold := Color(1.0, 0.84, 0.0)
	var white := Color(1.0, 1.0, 1.0, 1.0)
	
	tabList[_active_tab].visible = false
	tabList[_active_tab].add_theme_color_override("font_color", white)
	_active_tab = newIdx
	tabList[_active_tab].visible = true
	tabList[_active_tab].add_theme_color_override("font_color", gold)

#endregion

#region Selection / buttons

func _on_slot_clicked(slot: InventorySlot) -> void:
	_selected_slot = slot

func _clear_selection() -> void:
	_selected_slot    = null

#endregion

#region Drag-and-drop handler (called by InventorySlot._drop_data)

func handle_drop(from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	var from_item:QuantitySlot = from_slot.itemQuantity
	if from_item == null:
		return

	if from_slot.slot_type == InventorySlot.SlotType.HOTBAR:
		if _hotbar:
			_hotbar.unassign_slot(from_slot)
	if from_slot.slot_type == InventorySlot.SlotType.SECONDARY or to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
		return

	_clear_selection()

#endregion

#region Slot type helpers

func getHUD() -> HUD:
	return self.get_parent()

#endregion
