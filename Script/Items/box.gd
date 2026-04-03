@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_chest.png")
extends Node3D
class_name Box

@export var labelText : String = "Box"
@export var inventory: Inventory = null

func get_inventory() -> Inventory:
	return inventory

func set_Label_Text(text:String) -> void:
	labelText = text

func _on_open() -> void:
	#$box.visible = false
	$box2.visible = false
	$"box-open2".visible = true
	#Audio.play("res://assets/audio/coin.ogg") # Play sound
	#$Open.play()

func _on_close() -> void:
	#$box.visible = true
	$"box-open2".visible = false
	$box2.visible = true
	#Audio.play("res://assets/audio/coin.ogg") # Play sound
	#$Close.play()
