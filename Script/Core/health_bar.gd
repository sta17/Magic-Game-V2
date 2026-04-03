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
	if health < max_health:
		_hp_bar.visible = true
	else:
		_hp_bar.visible = false

func _is_dead() -> bool:
	if health <= 0.0:
		return true
	return false
