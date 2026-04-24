extends Node3D
class_name DropItemComponent

@export var DROP_CHANCE:  float = 0.6
@export var _PickupScene : PackedScene = preload("res://Scenes/PickUpItem.tscn")
@export var drop_table: Array[ItemData] = []

func _try_drop_items() -> void:
	for item in drop_table:
		if randf() < DROP_CHANCE:
			_spawn_pickup(item.duplicate(true))

func _spawn_pickup(item: ItemData = null, quantityCounter : QuantitySlot = null) -> void:
	var _PickupItem: PickUpItem = _PickupScene.instantiate()
	if not item == null:
		_PickupItem.item = item
	elif not quantityCounter == null:
		_PickupItem.quantityCounter = quantityCounter
	_PickupItem.position = self.position
	get_tree().current_scene.add_child(_PickupItem)
	_PickupItem._setup()
