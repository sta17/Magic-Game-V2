extends Control
class_name PassiveHotbar

const _SLOT_SCENE := preload("res://Scenes/UI/InventorySlot.tscn")

## A row of dedicated slots for passive abilities, visible only in the ability UI.
## Passive abilities placed here apply their bonuses automatically.

const SLOT_COUNT: int = 5
const SLOT_W:     float = 60.0
const SLOT_H:     float = 60.0
const SLOT_GAP:   float = 6.0

var _slots: Array[InventorySlot] = []
var _items: Array = []  # AbilityData or null, size = SLOT_COUNT

var parentScript: Control

func _ready() -> void:
	_items.resize(SLOT_COUNT)
	_items.fill(null)
	custom_minimum_size = Vector2(SLOT_COUNT * (SLOT_W + SLOT_GAP) - SLOT_GAP, SLOT_H)

func init(new_parentScript: Control) -> void:
	self.parentScript = new_parentScript
	for i in SLOT_COUNT:
		var slot := _SLOT_SCENE.instantiate() as InventorySlot
		slot.slot_type = InventorySlot.SlotType.PASSIVE_HOTBAR
		slot.position  = Vector2(i * (SLOT_W + SLOT_GAP), 0.0)
		slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		slot.mouse_item_hover.connect(parentScript.getHUD()._on_slot_mouse_item_hover)
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
		var tmp:Slot      = _items[from_idx]
		_items[from_idx] = _items[to_idx]
		_items[to_idx]   = tmp
	else:
		_items[to_idx] = from_slot.item

	_refresh_display()

func unassign_slot(slot: InventorySlot) -> void:
	var idx := _slots.find(slot)
	if idx != -1:
		_items[idx] = null
		_refresh_display()

## Auto-assign a passive ability to the first empty slot, expanding if full.
func auto_add(ability: AbilityData) -> void:
	for i in _items.size():
		if _items[i] == null:
			_items[i] = ability
			_refresh_display()
			return
	# No empty slot — add a new one
	var new_slot := _SLOT_SCENE.instantiate() as InventorySlot
	new_slot.slot_type = InventorySlot.SlotType.PASSIVE_HOTBAR
	new_slot.position  = Vector2(_slots.size() * (SLOT_W + SLOT_GAP), 0.0)
	new_slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
	new_slot.mouse_item_hover.connect(parentScript.getHUD()._on_slot_mouse_item_hover)
	add_child(new_slot)
	_slots.append(new_slot)
	_items.append(ability)
	custom_minimum_size = Vector2(_slots.size() * (SLOT_W + SLOT_GAP) - SLOT_GAP, SLOT_H)
	_refresh_display()

## Remove a specific ability instance from the hotbar.
func remove_ability_ref(ability: AbilityData) -> void:
	for i in _items.size():
		if _items[i] == ability:
			_items[i] = null
			_refresh_display()
			return

func _refresh_display() -> void:
	for i in _slots.size():
		_slots[i].set_item(_items[i],false,true)

## Passive stat aggregation — queried by player every physics frame.
func get_passive_speed_bonus() -> float:
	var total := 0.0
	for ab:Slot  in _items:
		if ab is AbilityData:
			total += ab.get_speed_bonus()
	return total

func get_passive_damage_bonus() -> float:
	var total := 0.0
	for ab:Slot  in _items:
		if ab is AbilityData:
			total += ab.get_damage_bonus()
	return total

func get_passive_health_regen() -> float:
	var total := 0.0
	for ab:Slot  in _items:
		if ab is AbilityData:
			total += ab.get_health_regen()
	return total
