@icon("res://Assets/Icons/Pixel-Boy/color/icon_life_bar.png")
extends Node3D
class_name Health_Bar

@onready var _hp_viewport:	SubViewport		= $HPViewport
@onready var _hp_bar:		ProgressBar		= $HPViewport/ProgressBar
@onready var _hp_sprite:	Sprite3D		= $HPSprite

func _setup_hp_sprite(s_health: float, s_max_health: float) -> void:
	_hp_bar.max_value = s_max_health
	_hp_bar.value = s_health
	_hp_sprite.texture = _hp_viewport.get_texture()
	if _hp_bar.value == _hp_bar.max_value:
		_hp_bar.visible = false

func _update_health_bar(health: float, max_health: float) -> void:
	if not _hp_bar:
		return
	_hp_bar.value = (health / max_health) * 100.0
	
	if _hp_bar.value == _hp_bar.max_value:
		_hp_bar.visible = true
	else:
		_hp_bar.visible = false
