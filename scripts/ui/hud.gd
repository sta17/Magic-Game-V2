extends CanvasLayer
class_name HUD

@onready var _hp_bar:       ProgressBar = $HPPanel/HPBar
@onready var _hp_label:     Label       = $HPPanel/HPLabel
@onready var _weapon_label: Label       = $AmmoPanel/WeaponLabel
@onready var _ammo_label:   Label       = $AmmoPanel/AmmoLabel
@onready var _reload_label: Label       = $AmmoPanel/ReloadLabel
@onready var _armor_label:  Label       = $EquipPanel/ArmorLabel
@onready var _acc_label:    Label       = $EquipPanel/AccLabel
@onready var _kill_label:   Label       = $EquipPanel/KillLabel
@onready var _score_label:  Label       = $ScoreLabel
@onready var _notif_label:  Label       = $NotifLabel
@onready var _crosshair:    Control     = $Crosshair
@onready var _death_screen: Control     = $DeathScreen
@onready var inv_panel:     Control     = $InvPanel
@onready var hotbar_panel:  Control     = $HotbarPanel

func update_hp(health: float, max_hp: float) -> void:
	var ratio := health / max_hp
	_hp_bar.value = ratio * 100.0
	_hp_label.text = str(int(health)) + " / " + str(int(max_hp))
	_hp_bar.add_theme_color_override("font_color", Color(1.0 - ratio, ratio, 0.1))

func update_ammo(weapon: WeaponData) -> void:
	if weapon:
		_ammo_label.text = str(weapon.ammo_current) + " / " + str(weapon.ammo_max)
		_weapon_label.text = weapon.item_name + "  [" + weapon.get_weapon_type_name() + "]"
	else:
		_ammo_label.text = "— / —"
		_weapon_label.text = "No Weapon"

func update_equip(armor: ArmorData, accessory: AccessoryData) -> void:
	_armor_label.text = "Armor: " + (armor.item_name if armor else "None")
	_acc_label.text = "Acc: " + (accessory.item_name if accessory else "None")

func show_reload(show: bool) -> void:
	_reload_label.visible = show

func show_notif(text: String, color: Color = Color.WHITE) -> void:
	_notif_label.text = text
	_notif_label.add_theme_color_override("font_color", color)
	_notif_label.visible = true
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(_notif_label):
		_notif_label.visible = false

func update_score(score: int) -> void:
	_score_label.text = "Score: " + str(score)

func update_kills(kills: int) -> void:
	_kill_label.text = "Kills: " + str(kills)

func show_death() -> void:
	_death_screen.visible = true

func set_crosshair_size(size: float) -> void:
	_crosshair.custom_minimum_size = Vector2(size * 2, size * 2)

func flash_damage() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0, 0, 0.35)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)
