extends NinePatchRect
class_name AbilityCard

@onready var nine_patch: NinePatchRect = $NinePatchRect
@onready var abi_slot: InventorySlot = $InventorySlot
@onready var title_lbl: Label = $Title_lbl
@onready var desc_lbl: Label = $Desc_lbl

func initalise(ability: AbilityData, width: float = 365.0) -> void:
	nine_patch = $NinePatchRect
	abi_slot = $InventorySlot
	title_lbl = $Title_lbl
	desc_lbl = $Desc_lbl
	
	abi_slot._ready()
	
	nine_patch.size = Vector2(365,85.0)
	
	abi_slot.set_item(ability)
	title_lbl.text	= ability.ability_name
	#title_lbl.size	= Vector2(width - 90.0, 24.0)
	desc_lbl.text	= ability.description
	#desc_lbl.size	= Vector2(width - 90.0, 40.0)
