@icon("res://Assets/Icons/Mine/UI.png")
extends CanvasLayer
class_name HUD

#region Variables
@onready var _hp_bar:		ProgressBar		= $HPPanel/HPBar
@onready var _hp_label:		Label			= $HPPanel/HPLabel
@onready var _notif_label:	Label			= $NotifLabel
@onready var player_UI:		PlayerUIMenu	= $player_UI_Menu
@onready var vendor_panel:	VendorUI		= $VendorWindow
@onready var main_hotbar:	HotbarUI		= $HotbarPanel
@onready var dialogWindow:	DialogWindow	= $DialogWindow
@onready var tooltip: 		Tooltip			= $Tooltip
@onready var screen: 		Control			= $Screen
@onready var loot_window: 	LootWindow		= $LootWindow

@export var default_cursor: Texture
@export var cross_cursor: Texture

var _player: Player = null
#endregion

#region Setup and Process

func _ready() -> void:	
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW,Vector2(7, 6))
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_CAN_DROP,Vector2(7, 6))
	Input.set_custom_mouse_cursor(cross_cursor, Input.CURSOR_FORBIDDEN,Vector2(7, 6))
	if player_UI.visible:
		player_UI.visible = false
	if vendor_panel.visible:
		vendor_panel.visible = false

func init(player: Player) -> void:
	_player    = player
	player_UI.mouse_slot_hover.connect(_on_slot_mouse_item_hover)
	loot_window.mouse_slot_hover.connect(_on_slot_mouse_item_hover)
	vendor_panel.mouse_slot_hover.connect(_on_slot_mouse_item_hover)
	main_hotbar.init(player)
	player_UI.init(player,main_hotbar)
	vendor_panel.init(player.inventory)
	loot_window.init(player.inventory)

func _process(_delta:float) -> void:
	if tooltip.visible:
		tooltip.position = screen.get_global_mouse_position()
		tooltip.position = tooltip.position + Vector2(6,8)

#region UI Interacts

func hotbarUseSelected() -> void:
	main_hotbar.use_selected()

func hotbarScroll(direction: int) -> void:
	main_hotbar.scroll(direction)

func dialogScroll(direction: int) -> void:
	dialogWindow.scroll(direction)

func dialogPromptLine() -> void:
	#dialogWindow.promptLine()
	dialogWindow.promptLines(1)

func dialogPromptPreviousLine() -> void:
	#dialogWindow.promptPreviousLine()
	dialogWindow.promptLines(-1)

func dialogSendSelection() -> void:
	dialogWindow.sendSelection()

#endregion

#region Misc

func update_hp(_amount:float = 0.0) -> void:
	var health: float = _player.health_component.health
	var max_hp: float = _player.health_component._max_hp()
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

func _on_slot_mouse_item_hover(currentSlot: Slot, status: bool) -> void:
	if status and currentSlot != null:
		tooltip.visible = true
		tooltip.setTooltip(currentSlot)
	else:
		tooltip.visible = false

#endregion

#endregion

#region Hide/Show UI

func Show_Text_Interact(player: Player, otherInteracter: NPC) -> void:
	main_hotbar.visible = false
	dialogWindow.visible = true
	dialogWindow.startChat(player,otherInteracter)

func Hide_Text_Interact() -> void:
	main_hotbar.visible = true
	dialogWindow.visible = false

func Show_Text_Vendor(otherInteracter: NPC, shoppinglist: Array[QuantitySlot] = []) -> void:
	main_hotbar.visible = false
	vendor_panel.visible = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Get Inventory or sell list
	vendor_panel.Show_Vendor(otherInteracter,shoppinglist)

func Hide_Text_Vendor() -> void:
	main_hotbar.visible = true
	vendor_panel.visible = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	vendor_panel.hide_vendor()

func ShowHide_Inventory() -> void:
	player_UI.visible = not player_UI.visible
	if player_UI.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func Show_Inventory() -> void:
	player_UI.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func Hide_Inventory() -> void:
	player_UI.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func ShowHide_Inventory_Box(interactble_entity: Box) -> void:
	player_UI.visible = not player_UI.visible
	if player_UI.visible:
		interactble_entity._on_open()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		interactble_entity._on_close()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player_UI.ShowHide_Inventory_Box(interactble_entity)

func ShowHide_Inventory_BoxMinimal(interactble_entity: Box) -> void:
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
	return player_UI.visible
#endregion
