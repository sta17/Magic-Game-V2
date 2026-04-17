@icon("res://Assets/Icons/Pixel-Boy/control/icon_bag.png")
extends Panel
class_name InventorySlot

enum SlotType { ANY, WEAPON, ARMOR, ACCESSORY, HOTBAR, ABILITY, PASSIVE_HOTBAR, VENDOR, SECONDARY }

@export var slot_type: SlotType = SlotType.ANY

var item: Slot = null  # ItemData or AbilityData
var itemQuantity: QuantitySlot = null
var is_equipped: bool = false
var is_ability:  bool = false
var is_selected: bool = false

var index: int = -1

signal slot_clicked(slot: InventorySlot)
signal mouse_item_hover(status: bool, currentSlot:Slot)

@onready var _icon_rect:	TextureRect	= $IconRect
@onready var _color_rect:	ColorRect	= $ColorRect
@onready var _label:		Label		= $SlotLabel
@onready var _amount:		Label		= $AmountLabel
@onready var _coloring:		Panel		= $Coloring
@onready var _frame:	NinePatchRect	= $NinePatchRect
@onready var _selection_frame:	NinePatchRect	= $Selected
@export var frameTexture: Texture2D = null
@export var emptyTexture: Texture2D = null

@export_group("Styles")
@export var _style_empty:         StyleBoxFlat
@export var _style_filled:        StyleBoxFlat

func _ready() -> void:
	# Duplicate so per-slot border_color mutations don't bleed into the shared resource
	if _style_filled:
		_style_filled = _style_filled.duplicate()
	_refresh_style()
	if frameTexture:
		_frame.texture = frameTexture

func set_item(new_item: Slot, equipped: bool = false, ability:bool = false) -> void:
	if new_item is QuantitySlot:
		item = (new_item as QuantitySlot).item
		itemQuantity = new_item
	elif ability:
		if new_item == null:
			item = null
			itemQuantity = null
			is_ability = ability
		else:
			item        = new_item
			itemQuantity = QuantitySlot.new()
			is_ability = ability
	else:
		item        = new_item
		itemQuantity = null
		
	is_equipped = equipped
	_update_display()

func _update_display() -> void:
	if item:
		_icon_rect.texture = item.get_icon()
		_icon_rect.visible = true
		_label.text        = ""
		_label.visible     = false
	else:
		_icon_rect.texture = null
		_icon_rect.visible = false
		_color_rect.visible = false
		match slot_type:
			SlotType.WEAPON:
				_label.text    = "Weapon"
				_label.visible = true
				_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1, 0.6))
				_color_rect.color = Color(1.0, 0.6, 0.1, 0.2)
				_color_rect.visible = true
			SlotType.ARMOR:
				_label.text    = "Armor"
				_label.visible = true
				_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0, 0.6))
				_color_rect.color = Color(0.3, 0.6, 1.0, 0.2)
				_color_rect.visible = true
			SlotType.ACCESSORY:
				_label.text    = "Access."
				_label.visible = true
				_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 0.6))
				_color_rect.color = Color(0.8, 0.3, 1.0, 0.2)
				_color_rect.visible = true
			SlotType.HOTBAR:
				_label.text    = ""
				_label.visible = false
			SlotType.ABILITY:
				_label.text    = ""
				_label.visible = false
			SlotType.PASSIVE_HOTBAR:
				_label.text    = ""
				_label.visible = false
			_:
				_label.text    = ""
				_label.visible = false
				_icon_rect.texture = emptyTexture
				_icon_rect.visible = true
				
	if item == null and itemQuantity == null:
		_amount.visible = false
	elif item is ItemData and itemQuantity != null:
		if itemQuantity.quantity > 1:
			_amount.visible = true
			_amount.text = str(itemQuantity.quantity)
		else:
			_amount.visible = false
	else:
		_amount.visible = false
	_refresh_style()

func _refresh_style() -> void:
	var sb: StyleBoxFlat
	
	if is_selected:
		_selection_frame.visible = true
	else:
		_selection_frame.visible = false
	
	if item:
		var c: Color = item.get_type_color()
		_style_filled.bg_color = Color(c.r, c.g, c.b, 0.2)
		sb = _style_filled
	else:
		sb = _style_empty
	_coloring.add_theme_stylebox_override("panel", sb)

func _get_drag_data(_pos: Vector2) -> Variant:
	if not item:
		return null
	var preview := TextureRect.new()
	preview.texture        = item.get_icon()
	preview.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(52, 52)
	preview.z_index        = 100
	preview.z_as_relative  = false
	set_drag_preview(preview)
	return self

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not data is InventorySlot:
		return false
	var from: InventorySlot = data
	if from == self or from.item == null:
		return false
	if from.itemQuantity == null and !from.is_equipped and !from.is_ability:
		return false
	if from.item == null and !from.is_equipped and !from.is_ability:
		return false
	match slot_type:
		SlotType.WEAPON:    return from.itemQuantity is QuantitySlot and from.itemQuantity.item.item_type == ItemData.ItemType.WEAPON
		SlotType.ARMOR:     return from.itemQuantity is QuantitySlot and from.itemQuantity.item.item_type == ItemData.ItemType.ARMOR
		SlotType.ACCESSORY: return from.itemQuantity is QuantitySlot and from.itemQuantity.item.item_type == ItemData.ItemType.ACCESSORY
		SlotType.ANY:
			if from.slot_type == SlotType.ANY and self.slot_type == SlotType.ANY:
				return true
			if from.slot_type == SlotType.SECONDARY and self.slot_type == SlotType.ANY:
				return true
			if from.slot_type == SlotType.ANY and self.slot_type == SlotType.SECONDARY:
				return true
			return from.slot_type != SlotType.ANY and from.slot_type != SlotType.ABILITY and from.slot_type != SlotType.PASSIVE_HOTBAR
		SlotType.SECONDARY:
			if from.slot_type == SlotType.SECONDARY and self.slot_type == SlotType.SECONDARY:
				return true
			if from.slot_type == SlotType.SECONDARY and self.slot_type == SlotType.ANY:
				return true
			if from.slot_type == SlotType.ANY and self.slot_type == SlotType.SECONDARY:
				return true
			return false
		SlotType.HOTBAR:
			# Passive abilities belong in the passive hotbar, not here
			if from.slot_type == SlotType.ABILITY and from.item is AbilityData \
					and (from.item as AbilityData).is_passive:
				return false
			return from.slot_type == SlotType.ANY or from.slot_type == SlotType.HOTBAR \
				or from.slot_type == SlotType.ABILITY
		SlotType.PASSIVE_HOTBAR:
			if from.slot_type == SlotType.PASSIVE_HOTBAR:
				return true
			return from.slot_type == SlotType.ABILITY and from.item is AbilityData \
				and (from.item as AbilityData).is_passive
		SlotType.ABILITY:
			# Drop from either hotbar onto an ability card to remove it from the hotbar
			return from.slot_type == SlotType.PASSIVE_HOTBAR \
				or from.slot_type == SlotType.HOTBAR
		SlotType.VENDOR:
			return false
	return false

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var from: InventorySlot = data
	var n : Control = get_parent() #hotbarPanel or InvPanel
	while n:
		if n.has_method("handle_drop"):
			n.handle_drop(from, self)
			return
		n = n.get_parent()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(self)

func _on_mouse_entered() -> void:
	if is_ability:
		mouse_item_hover.emit(item,true)
	else:
		mouse_item_hover.emit(itemQuantity,true)

func _on_mouse_exited() -> void:
	mouse_item_hover.emit(null,false)
