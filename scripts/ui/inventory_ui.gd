extends Control
class_name InventoryUI

const _SLOT_SCENE := preload("res://scenes/inventory_slot.tscn")

var _inventory: Inventory = null
var _equipment: EquipmentManager = null
var _ability_list: AbilityList = null
var _grid_slots: Array[InventorySlot] = []
var _player: Player = null
var _hotbar = null
var _selected_slot: InventorySlot = null
var _active_tab: int = 0

var passive_hotbar: PassiveHotbar = null

#region Scene node references

@onready var _tab_inv_btn: Button          = $InvBox/TabInvBtn
@onready var _tab_abi_btn: Button          = $InvBox/TabAbiBtn
@onready var _inv_content: Control         = $InvBox/InvContent
@onready var _abi_content: Control         = $InvBox/AbiContent

@onready var _eq_weapon_slot: InventorySlot    = $InvBox/InvContent/WpnSlot
@onready var _eq_armor_slot: InventorySlot     = $InvBox/InvContent/ArmSlot
@onready var _eq_accessory_slot: InventorySlot = $InvBox/InvContent/AccSlot
@onready var _count_label: Label           = $InvBox/InvContent/InvCountLabel
@onready var _grid_root: Control           = $InvBox/InvContent/GridRoot
@onready var _tooltip: RichTextLabel       = $InvBox/InvContent/Tooltip
@onready var _use_btn: Button              = $InvBox/InvContent/UseBtn
@onready var _drop_btn: Button             = $InvBox/InvContent/DropBtn

@onready var _abilities_container: Control = $InvBox/AbiContent/AbiScroll/AbilitiesContainer

#endregion

#region Public API

func set_hotbar(h) -> void:
	_hotbar = h

func get_passive_speed_bonus() -> float:
	return passive_hotbar.get_passive_speed_bonus() if passive_hotbar else 0.0

func get_passive_damage_bonus() -> float:
	return passive_hotbar.get_passive_damage_bonus() if passive_hotbar else 0.0

func get_passive_health_regen() -> float:
	return passive_hotbar.get_passive_health_regen() if passive_hotbar else 0.0

func auto_add_passive(ability: AbilityData) -> void:
	if passive_hotbar:
		passive_hotbar.auto_add(ability)

func auto_remove_passive(ability: AbilityData) -> void:
	if passive_hotbar:
		passive_hotbar.remove_ability_ref(ability)

func init(player: Player) -> void:
	_player    = player
	_inventory = player.inventory
	_equipment = player.equipment

	_inventory.inventory_changed.connect(_rebuild)
	_equipment.weapon_equipped.connect(func(_w): _rebuild())
	_equipment.armor_equipped.connect(func(_a): _rebuild())
	_equipment.accessory_equipped.connect(func(_ac): _rebuild())
	_equipment.slot_cleared.connect(func(_s): _rebuild())

	_tab_inv_btn.pressed.connect(func(): _set_tab(0))
	_tab_abi_btn.pressed.connect(func(): _set_tab(1))

	_eq_weapon_slot.slot_clicked.connect(_on_slot_clicked)
	_eq_armor_slot.slot_clicked.connect(_on_slot_clicked)
	_eq_accessory_slot.slot_clicked.connect(_on_slot_clicked)

	_use_btn.pressed.connect(_on_use_pressed)
	_drop_btn.pressed.connect(_on_drop_pressed)
	_use_btn.visible  = false
	_drop_btn.visible = false

	_ability_list = player.ability_list
	_ability_list.changed.connect(_rebuild_abilities)

	passive_hotbar = PassiveHotbar.new()
	_abilities_container.add_child(passive_hotbar)

	_build_grid()
	_rebuild_abilities()
	_set_tab(0)
	_refresh_eq_slots()
	_refresh_grid_slots()

func _build_grid() -> void:
	_grid_slots.clear()
	var cols := 6
	var step := 66.0  # slot size (60) + gap (6)
	for i in range(_inventory.capacity):
		var slot := _SLOT_SCENE.instantiate() as InventorySlot
		slot.slot_type = InventorySlot.SlotType.ANY
		slot.position  = Vector2((i % cols) * step, (i / cols) * step)
		slot.slot_clicked.connect(_on_slot_clicked)
		_grid_root.add_child(slot)
		_grid_slots.append(slot)

func _rebuild_abilities() -> void:
	# Clear dynamic nodes but keep the persistent passive_hotbar
	for child in _abilities_container.get_children():
		if child != passive_hotbar:
			child.queue_free()

	var stride  := 100.0
	var col_w   := 365.0
	var col_gap := 10.0
	var left_x  := 0.0
	var right_x := col_w + col_gap

	var active_abs  := _ability_list.abilities.filter(func(a: AbilityData): return not a.is_passive)
	var passive_abs := _ability_list.abilities.filter(func(a: AbilityData): return a.is_passive)

	# ── Left column: Active abilities ────────────────────────────────
	var y_left := 0.0
	_make_section_label("— ACTIVE ABILITIES —", left_x, y_left, Color(1.0, 0.75, 0.2), col_w)
	y_left += 28.0
	for ab in active_abs:
		_make_ability_card(Vector2(left_x, y_left), ab, col_w)
		y_left += stride
	if active_abs.is_empty():
		y_left += 30.0

	# ── Right column: Passive hotbar + abilities ─────────────────────
	var y_right := 0.0
	_make_section_label("— PASSIVE ABILITIES —", right_x, y_right, Color(0.0, 1.0, 0.6), col_w)
	y_right += 28.0

	passive_hotbar.position = Vector2(right_x, y_right)
	y_right += 70.0
	y_right += 8.0

	for ab in passive_abs:
		_make_ability_card(Vector2(right_x, y_right), ab, col_w)
		y_right += stride

	_abilities_container.custom_minimum_size = Vector2(0, 0)

func _make_section_label(text: String, x: float, y: float, color: Color, width: float = 365.0) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(x, y)
	lbl.size     = Vector2(width, 22.0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	_abilities_container.add_child(lbl)

func _make_ability_card(pos: Vector2, ability: AbilityData, width: float = 365.0) -> void:
	var card := ColorRect.new()
	card.position = pos
	card.size     = Vector2(width, 90.0)
	card.color    = Color(0.08, 0.1, 0.18, 0.9)
	_abilities_container.add_child(card)

	var slot := _SLOT_SCENE.instantiate() as InventorySlot
	slot.slot_type = InventorySlot.SlotType.ABILITY
	slot.position  = Vector2(10.0, 10.0)
	slot.custom_minimum_size = Vector2(64.0, 64.0)
	card.add_child(slot)
	slot.set_item(ability)

	var title_lbl := Label.new()
	title_lbl.text     = ability.ability_name
	title_lbl.position = Vector2(84.0, 12.0)
	title_lbl.size     = Vector2(width - 90.0, 24.0)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	card.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text          = ability.description
	desc_lbl.position      = Vector2(84.0, 40.0)
	desc_lbl.size          = Vector2(width - 90.0, 40.0)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	card.add_child(desc_lbl)

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

func _rebuild() -> void:
	_refresh_grid_slots()
	_refresh_eq_slots()

func _refresh_eq_slots() -> void:
	_eq_weapon_slot.set_item(_equipment.equipped_weapon)
	_eq_armor_slot.set_item(_equipment.equipped_armor)
	_eq_accessory_slot.set_item(_equipment.equipped_accessory)

func _refresh_grid_slots() -> void:
	_count_label.text = "INVENTORY  (%d / %d)" % [_inventory.items.size(), _inventory.capacity]
	var visible_items := _inventory.items.filter(func(it): return not _equipment.is_equipped(it))
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
		_tooltip.text = "[color=#%s][b]%s[/b][/color]\n%s" % [
			slot.item.get_type_color().to_html(false),
			slot.item.item_name,
			slot.item.description,
		]
		var is_eq := _is_eq_slot(slot)
		_use_btn.visible  = not is_eq and slot.item.item_type == ItemData.ItemType.CONSUMABLE
		_drop_btn.visible = not is_eq
	else:
		_tooltip.text     = ""
		_use_btn.visible  = false
		_drop_btn.visible = false

func _on_use_pressed() -> void:
	if _selected_slot and _selected_slot.item and _player:
		_player.use_item(_selected_slot.item)
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
	_tooltip.text     = ""
	_use_btn.visible  = false
	_drop_btn.visible = false

#endregion

#region Drag-and-drop handler (called by InventorySlot._drop_data)

func handle_drop(from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	var from_item = from_slot.item
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
	else:
		# Inventory ↔ Inventory swap (reorder by item reference, not slot index)
		var fi := _inventory.items.find(from_slot.item)
		var ti := _inventory.items.find(to_slot.item)
		if fi != -1 and ti != -1:
			var tmp        := _inventory.items[fi]
			_inventory.items[fi] = _inventory.items[ti]
			_inventory.items[ti] = tmp
			_inventory.inventory_changed.emit()

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
