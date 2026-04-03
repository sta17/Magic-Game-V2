@icon("res://Assets/Icons/Mine/UI.png")
extends Control
class_name Tooltip

@onready var tooltipText: RichTextLabel = $MarginContainer/GridContainer/tooltip_text

func setTooltip(item:Slot) -> void:
	tooltipText.text = item.get_tooltip()

func show_tooltip() -> void:
	visible = true
	
func hide_tooltip() -> void:
	visible = false
