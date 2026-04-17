@icon("res://Assets/Icons/Mine/UI.png")
extends NinePatchRect
class_name ShoppingCard

@onready var abi_slot: InventorySlot = $InventorySlot
@onready var title_lbl: Label = $Title_lbl
@onready var desc_lbl: Label = $Desc_lbl

var resizeSize: Vector2 = Vector2(365,85)

func initalise(new_item: ItemData) -> void:
	abi_slot = $InventorySlot
	title_lbl = $Title_lbl
	desc_lbl = $Desc_lbl
	
	abi_slot._ready()
	
	abi_slot.set_item(new_item,false,true)
	title_lbl.text	= new_item.getName()
	desc_lbl.text	= "Cost Kr:" + str(new_item.value)
	
	anchor_left = 0
	anchor_right = 0 
	anchor_top = 0
	anchor_bottom = 0
	
	call_deferred("set", "size", resizeSize)
	
	anchor_left = 4
	anchor_right = 4 
	anchor_top = 4
	anchor_bottom = 4

func getSlot() -> InventorySlot:
	return abi_slot
