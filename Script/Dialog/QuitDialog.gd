extends DialogOptionResults
class_name DialogOptionQuitDialog

var player:Player

func _ready() -> void:
	functionCall = true

func execute(_parameters: Array = []) -> void:
	player = _parameters[0]
	player.ExitDialogeUI()
