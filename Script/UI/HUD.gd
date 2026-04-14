@icon("res://Assets/Icons/Mine/UI.png")
extends CanvasLayer
class_name HUD

#region Variables
@onready var _hp_bar:		ProgressBar		= $HPPanel/HPBar
@onready var _hp_label:		Label			= $HPPanel/HPLabel
@onready var _notif_label:	Label			= $NotifLabel
@onready var inv_panel:		InventoryUI		= $InvPanel
@onready var vendor_panel:	VendorUI		= $VendorWindow
@onready var hotbar_panel:	HotbarUI		= $HotbarPanel
@onready var dialogWindow:	DialogWindow	= $DialogWindow
@onready var tooltip: 		Tooltip			= $Tooltip
@onready var screen: 		Control			= $Screen
@onready var loot_window: 	LootWindow		= $LootWindow

@export var default_cursor: Texture
@export var cross_cursor: Texture
#endregion

#region Setup and Process

func _ready() -> void:	
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW,Vector2(7, 6))
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_CAN_DROP,Vector2(7, 6))
	Input.set_custom_mouse_cursor(cross_cursor, Input.CURSOR_FORBIDDEN,Vector2(7, 6))

func _process(_delta:float) -> void:
	if tooltip.visible:
		tooltip.position = screen.get_global_mouse_position()
		tooltip.position = tooltip.position + Vector2(6,8)

#endregion

#region Misc

func update_hp(health: float, max_hp: float) -> void:
	var ratio := health / max_hp
	_hp_bar.value = ratio * 100.0
	_hp_label.text = str(int(health)) + " / " + str(int(max_hp))
	_hp_bar.add_theme_color_override("font_color", Color(1.0 - ratio, ratio, 0.1))

func show_death() -> void:
	pass

func show_notif(text: String, color: Color = Color.WHITE) -> void:
	_notif_label.text = text
	_notif_label.add_theme_color_override("font_color", color)
	_notif_label.visible = true
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(_notif_label):
		_notif_label.visible = false

func flash_damage() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0, 0, 0.35)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)

func _on_slot_mouse_item_hover(status: bool, currentSlot: Slot) -> void:
	if status and currentSlot != null:
		tooltip.visible = true
		tooltip.setTooltip(currentSlot)
	else:
		tooltip.visible = false

#endregion

#region Hide/Show UI

func Show_Text_Interact(player: Player, otherInteracter: NPC) -> void:
	hotbar_panel.visible = false
	dialogWindow.visible = true
	dialogWindow.startChat(player,otherInteracter)

func Hide_Text_Interact() -> void:
	hotbar_panel.visible = true
	dialogWindow.visible = false

func Show_Text_Vendor(_player: Player, otherInteracter: NPC, shoppinglist: Array[QuantitySlot] = []) -> void:
	hotbar_panel.visible = false
	vendor_panel.visible = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Get Inventory or sell list
	vendor_panel.Show_Vendor(otherInteracter,shoppinglist)

func Hide_Text_Vendor() -> void:
	hotbar_panel.visible = true
	vendor_panel.visible = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	vendor_panel.hide_vendor()

func ShowHide_Inventory() -> void:
	inv_panel.visible = not inv_panel.visible
	if inv_panel.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func Show_Inventory() -> void:
	inv_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func Hide_Inventory() -> void:
	inv_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func ShowHide_Inventory_Box(interactble_entity: Box) -> void:
	inv_panel.visible = not inv_panel.visible
	if inv_panel.visible:
		interactble_entity._on_open()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		interactble_entity._on_close()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	inv_panel.ShowHide_Inventory_Box(interactble_entity)

func ShowHide_Inventory_BoxMinimal(interactble_entity: Box) -> void:
	#inv_panel.visible = not inv_panel.visible
	loot_window.visible = not loot_window.visible
	if loot_window.visible:
		interactble_entity._on_open()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		interactble_entity._on_close()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	loot_window.ShowHide_Inventory_Box(interactble_entity)

#endregion

#region Bool checks
func isLootWindowVisible() -> bool:
	return loot_window.visible

func isInv_PanelVisible() -> bool:
	return inv_panel.visible
#endregion
