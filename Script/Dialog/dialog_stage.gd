extends Resource
class_name DialogStage

@export var text: Array[String] = []
@export var icon: Texture2D = null
@export var options: Array[String] = []
@export var results: Array[DialogOptionResults] = []
## Is the Stage instead supposed to just to try to auto execute the method in first Options Results?
@export var auto_execute_first_result: bool = false
