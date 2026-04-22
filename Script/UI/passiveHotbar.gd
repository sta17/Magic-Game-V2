extends Control
class_name PassiveHotbar

signal mouse_slot_hover(status: bool, currentSlot:Slot)

const _SLOT_SCENE := preload("res://Scenes/UI/InventorySlot.tscn")

## A row of dedicated slots for passive abilities, visible only in the ability UI.
## Passive abilities placed here apply their bonuses automatically.

const SLOT_COUNT: int = 5
const SLOT_W:     float = 60.0
const SLOT_H:     float = 60.0
const SLOT_GAP:   float = 6.0

var _slots: Array[InventorySlot] = []
var _ability_list: AbilityList = null

func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_COUNT * (SLOT_W + SLOT_GAP) - SLOT_GAP, SLOT_H)

func init(passive_ability_list: AbilityList) -> void:
	_ability_list = passive_ability_list
	_ability_list.abilities.resize(SLOT_COUNT)
	_ability_list.abilities.fill(null)
	_ability_list.changeAdded.connect(auto_add)
	_ability_list.changeRemoved.connect(_refresh_display)
	for i in SLOT_COUNT:
		var slot := _SLOT_SCENE.instantiate() as InventorySlot
		slot.slot_type = InventorySlot.SlotType.PASSIVE_HOTBAR
		slot.position  = Vector2(i * (SLOT_W + SLOT_GAP), 0.0)
		slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		slot.mouse_item_hover.connect(_on_slot_mouse_item_hover)
		add_child(slot)
		_slots.append(slot)

func handle_drop(from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	var to_idx := _slots.find(to_slot)
	if to_idx == -1:
		return

	if from_slot.slot_type == InventorySlot.SlotType.PASSIVE_HOTBAR:
		# Rearrange within passive hotbar
		var from_idx := _slots.find(from_slot)
		if from_idx == -1:
			return
		var tmp := _ability_list.abilities[from_idx]
		_ability_list.abilities[from_idx] = _ability_list.abilities[to_idx]
		_ability_list.abilities[to_idx]   = tmp
	else:
		_ability_list.abilities[to_idx] = from_slot.item

	_refresh_display()

func unassign_slot(slot: InventorySlot) -> void:
	var idx := _slots.find(slot)
	if idx != -1:
		_ability_list.abilities[idx] = null
		_refresh_display()

## Auto-assign a passive ability to the first empty slot, expanding if full.
func auto_add(_ability: AbilityData) -> void:
	for i in _ability_list.abilities.size():
		if _ability_list.abilities[i] == null:
			_refresh_display()
			return
	# No empty slot — add a new one
	var new_slot := _SLOT_SCENE.instantiate() as InventorySlot
	new_slot.slot_type = InventorySlot.SlotType.PASSIVE_HOTBAR
	new_slot.position  = Vector2(_slots.size() * (SLOT_W + SLOT_GAP), 0.0)
	new_slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
	new_slot.mouse_item_hover.connect(_on_slot_mouse_item_hover)
	add_child(new_slot)
	_slots.append(new_slot)
	custom_minimum_size = Vector2(_slots.size() * (SLOT_W + SLOT_GAP) - SLOT_GAP, SLOT_H)
	_refresh_display()

func _refresh_display() -> void:
	for i in _slots.size():
		_slots[i].set_item(_ability_list.abilities[i],false,true)

func _on_slot_mouse_item_hover(currentSlot: Slot, status: bool) -> void:
	mouse_slot_hover.emit(currentSlot,status)
