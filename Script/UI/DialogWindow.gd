@icon("res://Assets/Icons/Mine/UI.png")
extends Control
class_name DialogWindow

const _dialogOption  := preload("res://Scenes/UI/DialogOption.tscn")

@onready var option_dump : VBoxContainer = $VBoxContainer/PlayerBox/Control/HScrollBar/VBoxContainer

@onready var npc_box: Panel = $VBoxContainer/NPCBox
@onready var npc_icon: TextureRect = $VBoxContainer/NPCBox/TextureRect
@onready var npc_text: Label = $VBoxContainer/NPCBox/Label

var player: Player
var otherInteracter: NPC
var interact_script: DialogScript

var _selected_index: int          = 0
var options : Array[DialogOption]
var currentTextArray: Array[String] = []
var currentLine: int = 0
var currentStage: DialogStage = null

func _ready() -> void:
	pass

func startChat(c_player: Player, c_otherInteracter: NPC) -> void:
	
	player = c_player
	otherInteracter = c_otherInteracter
	interact_script = otherInteracter.interact_script

	var stage: int = 0
	options.assign(option_dump.get_children(false))
	newStage(stage)

func newStage(stage: int) -> void:
	currentLine = 0
	_selected_index = 0
	currentStage = interact_script.getStage(stage)
	generateOptions()

func generateOptions() -> void:
	
	currentTextArray = currentStage.text
	npc_icon.texture = currentStage.icon
	npc_text.text = currentTextArray[currentLine]
	
	# start here
	for slot in options:
		slot.queue_free()
	options.clear()

	var optionsText: Array[String] = currentStage.options
	# get chat options
	for x in optionsText.size():
		var dialog_Option: DialogOption = _dialogOption.instantiate()
		dialog_Option._ready()
		dialog_Option.select_button.pressed.connect(buttonPressed)
		dialog_Option.index = x
		dialog_Option.set_text(optionsText[x])
		option_dump.add_child(dialog_Option)
		options.append(dialog_Option)
		
		# set up listeners for buttons and selections

	options[0].select()

func buttonPressed(button: Button) -> void:
	var chat_option: DialogOption = button.get_parent()
	options[_selected_index].select()
	_selected_index = chat_option.index
	handleOption(chat_option)

func promptLine() -> bool:
	if currentLine < (currentTextArray.size()-1):
		currentLine += 1
		npc_text.text = currentTextArray[currentLine]
		return true
	else:
		return false

func sendSelection() -> void:
	# this is for turning input into options selected
	handleOption(options[_selected_index])

func handleOption(chat_option: DialogOption) -> void:
	
	if currentStage.results.size() == 0 or currentStage.results[chat_option.index] == null:
		player.ExitDialogeUI()
	else:
		if currentStage.results[chat_option.index].nextStage > 0:
			newStage(currentStage.results[chat_option.index].nextStage)
		elif currentStage.results[chat_option.index].nextStage == -1:
			player.ExitDialogeUI()
		elif currentStage.results[chat_option.index].functionCall:
			currentStage.results[chat_option.index].execute([player,otherInteracter])

## Cycle the selected options. direction: -1 = left, +1 = right.
func scroll(direction: int) -> void:
	options[_selected_index].select()
	_selected_index = (_selected_index + direction + options.size()) % options.size()
	options[_selected_index].select()
