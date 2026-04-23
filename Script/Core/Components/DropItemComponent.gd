extends Node3D
class_name DropItemComponent

@export var DROP_CHANCE:  float = 0.6
@export var _PickupScene := preload("res://Scenes/PickUpItem.tscn")
@export var drop_table: Array[ItemData] = []

func _try_drop_items() -> void:
	for item in drop_table:
		if randf() < DROP_CHANCE:
			_spawn_pickup(item.duplicate(true))

func _spawn_pickup(item: ItemData) -> void:
	var pickup: PickUpItem = _PickupScene.instantiate()
	pickup.item = item
	# Set position BEFORE add_child so _ready() captures the correct bob base Y
	pickup.position = global_position + Vector3(
		randf_range(-0.6, 0.6), 0.8, randf_range(-0.6, 0.6)
	)
	get_tree().current_scene.add_child(pickup)
