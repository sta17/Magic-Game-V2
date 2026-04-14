@icon("res://Assets/Icons/Pixel-Boy/node/icon_dialog.png")
extends Resource
class_name DialogScript

# How it works either a dictionary or an array containing the options and lines
@export var dialogues: Array[DialogStage] = []
## Is the Stage instead supposed to just to try to auto execute the method in first Options Results?
@export var auto_execute_first_result: bool = false

func getStage(index: int) -> DialogStage:
	return dialogues[index]

func check_Auto_execute() -> bool:
	return auto_execute_first_result
