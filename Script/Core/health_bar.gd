@icon("res://Assets/Icons/Pixel-Boy/color/icon_life_bar.png")
extends Node3D
class_name Health_Bar

@onready var _hp_viewport:	SubViewport		= $HPViewport
@onready var _hp_bar:		ProgressBar		= $HPViewport/ProgressBar
@onready var _hp_sprite:	Sprite3D		= $HPSprite

var health: float
var max_health: float

func _setup_hp_sprite(s_health: float, s_max_health: float) -> void:
	self.health = s_health
	self.max_health = s_max_health
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_hp_sprite.texture = _hp_viewport.get_texture()
	if health == max_health:
		_hp_bar.visible = false

func _update_health_bar(change: float) -> void:
	health += change
	if not _hp_bar:
		return
	_hp_bar.value = (health / max_health) * 100.0
	_spawn_damage_number(change)
	if health < max_health:
		_hp_bar.visible = true
	else:
		_hp_bar.visible = false

func _is_dead() -> bool:
	if health <= 0.0:
		return true
	return false

func _is_damaged() -> bool:
	if health != max_health:
		return true
	return false

func _spawn_damage_number(amount: float) -> void:
	var label := Label3D.new()
	label.text = "-%d" % int(amount)
	label.font_size = 48
	label.modulate = Color(1.0, 0.3, 0.1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector3(0, 2.4, 0)
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 1.2, 0), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free).set_delay(0.8)
