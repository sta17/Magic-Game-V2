@icon("res://Assets/Icons/Mine/UI.png")
extends Control
class_name HotbarUI

@onready var _slot_holder: Control = $SlotHolder

const _SLOT_SCENE := preload("res://Scenes/UI/InventorySlot.tscn")
const SLOT_COUNT: int = 8
const SLOT_W:   float = 60.0
const SLOT_H:   float = 60.0
const SLOT_GAP: float = 6.0

var _player: Player					= null
var _inventory: Inventory			= null
var _hotbar_items: Array			= []    # Array[ItemData or null], size = SLOT_COUNT
var _hotbar_is_ability: Array		= []    # Array[bool], true = ability (not from inventory)
var _slots: Array[InventorySlot]	= []
var _selected_index: int			= 0

func init(player: Player) -> void:
	_player    = player
	_inventory = player.inventory
	_hotbar_items.resize(SLOT_COUNT)
	_hotbar_items.fill(null)
	_hotbar_is_ability.resize(SLOT_COUNT)
	_hotbar_is_ability.fill(false)
	_inventory.inventory_changed.connect(_on_inventory_changed)
	_build_ui()

func _build_ui() -> void:
	for i in SLOT_COUNT:
		var slot := _SLOT_SCENE.instantiate() as InventorySlot
		slot.slot_type = InventorySlot.SlotType.HOTBAR
		slot.position = Vector2(SLOT_GAP + (i * (SLOT_W + SLOT_GAP)), 4.0)
		slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		slot.itemQuantity = QuantitySlot.new()
		_slot_holder.add_child(slot)
		_slots.append(slot)
		slot.slot_clicked.connect(func(s: InventorySlot): _on_slot_clicked(_slots.find(s)))

		# Slot number label (top-left corner)
		var num := Label.new()
		num.text = str(i + 1)
		num.position = Vector2(3.0, 1.0)
		num.size = Vector2(18.0, 14.0)
		num.add_theme_font_size_override("font_size", 10)
		num.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(num)

	_refresh_display()

func _on_slot_clicked(index: int) -> void:
	if index < 0:
		return
	_selected_index = index
	_refresh_display()

## Cycle the selected hotbar slot. direction: -1 = left, +1 = right.
func scroll(direction: int) -> void:
	_selected_index = (_selected_index + direction + SLOT_COUNT) % SLOT_COUNT
	_refresh_display()

## Use the item or ability in the currently selected hotbar slot.
func use_selected() -> void:
	var data:Slot = _hotbar_items[_selected_index] if _selected_index < _hotbar_items.size() else null
	if data == null or _player == null:
		return
	if data is AbilityData:
		data.execute(_player)
	else:
		_player.use_item(data)

## Remove the assignment for a specific slot (called when dragging out to inventory).
func unassign_slot(slot: InventorySlot) -> void:
	var idx := _slots.find(slot)
	if idx != -1:
		_hotbar_items[idx] = null
		_hotbar_is_ability[idx] = false
		_refresh_display()

## Called by InventorySlot._drop_data when a drag is dropped onto a hotbar slot.
func handle_drop(from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	var to_idx := _slots.find(to_slot)
	if to_idx == -1:
		return

	if from_slot.slot_type == InventorySlot.SlotType.HOTBAR:
		# Swap two hotbar slots (carry the ability flag along)
		var from_idx := _slots.find(from_slot)
		if from_idx == -1:
			return
		var tmp:Slot = _hotbar_items[from_idx]
		_hotbar_items[from_idx] = _hotbar_items[to_idx]
		_hotbar_items[to_idx] = tmp
		var tmp_flag: bool = _hotbar_is_ability[from_idx]
		_hotbar_is_ability[from_idx] = _hotbar_is_ability[to_idx]
		_hotbar_is_ability[to_idx] = tmp_flag
	else:
		# Assign an inventory item or ability to this hotbar slot
		_hotbar_items[to_idx] = from_slot.item
		_hotbar_is_ability[to_idx] = (from_slot.slot_type == InventorySlot.SlotType.ABILITY)
		if (from_slot.slot_type == InventorySlot.SlotType.ABILITY):
			_hotbar_items[to_idx] = from_slot.item
		else:
			_hotbar_items[to_idx] = from_slot.itemQuantity

	_refresh_display()

func _on_inventory_changed() -> void:
	# Clear hotbar references to items no longer in inventory (skip ability slots)
	for i in SLOT_COUNT:
		if _hotbar_is_ability[i]:
			continue
		if _hotbar_items[i] != null:
			if not _inventory.items.has(_hotbar_items[i]):
				_hotbar_items[i] = null
	_refresh_display()

## Aggregate passive stat bonuses from all passive AbilityData on the hotbar.
func get_passive_speed_bonus() -> float:
	var total := 0.0
	for slot_item:Slot in _hotbar_items:
		if slot_item is AbilityData and slot_item.is_passive:
			total += slot_item.get_speed_bonus()
	return total

func get_passive_damage_bonus() -> float:
	var total := 0.0
	for slot_item:Slot in _hotbar_items:
		if slot_item is AbilityData and slot_item.is_passive:
			total += slot_item.get_damage_bonus()
	return total

func get_passive_health_regen() -> float:
	var total := 0.0
	for slot_item:Slot in _hotbar_items:
		if slot_item is AbilityData and slot_item.is_passive:
			total += slot_item.get_health_regen()
	return total

func _refresh_display() -> void:
	for i in _slots.size():
		var slot: InventorySlot = _slots[i]
		var slot_data:Slot = _hotbar_items[i]  # ItemData or AbilityData
		slot.is_selected = (i == _selected_index)
		slot.set_item(slot_data,false, true)
