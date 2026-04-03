@icon("res://Assets/Icons/Mine/UI.png")
extends NinePatchRect
class_name AbilityCard

@onready var abi_slot: InventorySlot = $InventorySlot
@onready var title_lbl: Label = $Title_lbl
@onready var desc_lbl: Label = $Desc_lbl

func initalise(ability: AbilityData) -> void:
	abi_slot = $InventorySlot
	title_lbl = $Title_lbl
	desc_lbl = $Desc_lbl
	
	abi_slot._ready()
	
	abi_slot.set_item(ability,false,true)
	title_lbl.text	= ability.getName()
	desc_lbl.text	= ability.description
	size = Vector2(365,85)
