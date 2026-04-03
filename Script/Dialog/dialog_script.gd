extends Resource
class_name DialogScript

# How it works either a dictionary or an array containing the options and lines
@export var dialogues: Array[DialogStage] = []

func getStage(index: int) -> DialogStage:
	return dialogues[index]
