extends CanvasLayer
class_name HUD

@onready var _hp_bar:       ProgressBar = $HPPanel/HPBar
@onready var _hp_label:     Label       = $HPPanel/HPLabel
@onready var _notif_label:  Label       = $NotifLabel
@onready var inv_panel:     Control     = $InvPanel
@onready var hotbar_panel:  Control     = $HotbarPanel

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
