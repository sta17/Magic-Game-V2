@icon("res://Assets/Icons/Pixel-Boy/control/icon_bag.png")
extends Control
class_name AbilityWindow

const _SLOT_SCENE := preload("res://scenes/UI/inventorySlot.tscn")
const _ACT_SCENE := preload("res://Scenes/UI/act_abi_label.tscn")
const _PAS_SCENE := preload("res://Scenes/UI/pas_abi_label.tscn")
const _PAS_HOT_SCENE := preload("res://Scenes/UI/PassiveHotbar.tscn")
const _ABI_CARD_SCENE := preload("res://Scenes/UI/ability_card.tscn")

var _ability_list: AbilityList = null
var _passive_ability_list: AbilityList = null
var _hotbar: HotbarUI = null
var _selected_slot: InventorySlot = null

signal mouse_slot_hover(status: bool, currentSlot:Slot)

#region Scene node references

@onready var passive_hotbar: PassiveHotbar	= $AbiScroll/PassiveHotbar
@onready var _abilities_container: Control	= $AbiScroll/AbilitiesContainer

#endregion

#region Setup

func init(ability_list: AbilityList, passive_ability_list: AbilityList, h: HotbarUI) -> void:
	_ability_list = ability_list
	_ability_list.changeAdded.connect(_rebuild_abilities)
	_ability_list.changeRemoved.connect(_rebuild_abilities)
	
	_passive_ability_list = passive_ability_list
	passive_hotbar.init(_passive_ability_list)
	passive_hotbar.mouse_slot_hover.connect(_on_slot_mouse_item_hover)

	_hotbar = h

	_rebuild_abilities()

#endregion

#region Bonuses

func get_passive_speed_bonus() -> float:
	return passive_hotbar.get_passive_speed_bonus() if passive_hotbar else 0.0

func get_passive_damage_bonus() -> float:
	return passive_hotbar.get_passive_damage_bonus() if passive_hotbar else 0.0

func get_passive_health_regen() -> float:
	return passive_hotbar.get_passive_health_regen() if passive_hotbar else 0.0

#endregion

#region Refresh

func _rebuild_abilities(_ability: AbilityData = null) -> void:
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
		_ABI_CARD.getSlot().mouse_item_hover.connect(_on_slot_mouse_item_hover)
		_ABI_CARD.position = Vector2(left_x, y_left)
		_abilities_container.add_child(_ABI_CARD)
		y_left += stride
	if active_abs.is_empty():
		y_left += 30.0
	
	var y_right:float = 90.0

	for ab:AbilityData in passive_abs:
		var _ABI_CARD : AbilityCard = _ABI_CARD_SCENE.instantiate()
		_ABI_CARD.initalise(ab)
		_ABI_CARD.getSlot().mouse_item_hover.connect(_on_slot_mouse_item_hover)
		_ABI_CARD.position = Vector2(right_x, y_right)
		_abilities_container.add_child(_ABI_CARD)
		y_right += stride

	_abilities_container.custom_minimum_size = Vector2(0, 0)

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
	elif from_slot.slot_type == InventorySlot.SlotType.PASSIVE_HOTBAR:
		if passive_hotbar:
			passive_hotbar.unassign_slot(from_slot)
	elif from_slot.slot_type == InventorySlot.SlotType.SECONDARY or to_slot.slot_type == InventorySlot.SlotType.SECONDARY:
		return

	_clear_selection()

#endregion

#region Slot type helpers

func _on_slot_mouse_item_hover(currentSlot: Slot, status: bool) -> void:
	mouse_slot_hover.emit(currentSlot,status)

#endregion
