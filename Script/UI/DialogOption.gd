@icon("res://Assets/Icons/Mine/UI.png")
extends Control
class_name DialogOption

@onready var text_Label: Label = $Label
@onready var select_button: Button = $Button

@export var select_icon: Texture2D
@export var normal_icon: Texture2D

var index: int = -1
var is_selected: bool = false

func _ready() -> void:
	is_selected = false
	select_button.icon = normal_icon
	text_Label = $Label
	select_button = $Button

func select() -> void:
	is_selected = !is_selected
	if is_selected:
		select_button.icon = select_icon
	else:
		select_button.icon = normal_icon

func set_text(text: String) -> void:
	text_Label.text = text

func _on_button_pressed() -> void:
	pass # Replace with function body.
