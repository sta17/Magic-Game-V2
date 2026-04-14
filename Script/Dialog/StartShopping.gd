@icon("res://Assets/Icons/Pixel-Boy/node/icon_coin.png")
extends DialogOptionResults
class_name DialogOptionStartShopping

@export var shoppinglist: Array[Slot] = []
var player:Player
var otherInteracter: NPC
var shoppinglistFixed: Array[QuantitySlot] = []

func _init() -> void:
	call_deferred("_ready")

func _ready() -> void:
	functionCall = true
	fixList()

func fixList() -> void:
	for i in range(shoppinglist.size()):
		if shoppinglist[i] is ItemData:
			var quantityWrapper: QuantitySlot = QuantitySlot.new()
			quantityWrapper.item = shoppinglist[i]
			quantityWrapper.quantity = 1
			shoppinglistFixed.append(quantityWrapper)
		elif shoppinglist[i] is QuantitySlot:
			shoppinglistFixed.append(shoppinglist[i])

func execute(_parameters: Array = []) -> void:
	player = _parameters[0]
	otherInteracter = _parameters[1]
	player.ExitDialogeUI()
	player.setState(player.PlayerState.UI)
	player._vendor_window(otherInteracter,shoppinglistFixed)
	# Do Nothing
