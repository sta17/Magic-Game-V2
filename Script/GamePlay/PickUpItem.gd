extends Area3D
class_name PickUpItem

@export var item : ItemData
@export var quantityCounter : QuantitySlot
@export var is_pickable := true
@export var autoCollect := false
@export var amount : int = 1
@export var addMeshModelOnStart : bool = true
var itemModel: Node3D
var toBeDeleted:bool = false
var radius:
	get: 
		return 0.6
var global_position_yless:
	get:
		return global_position * Vector3(1, 0, 1)

func _ready():
	itemSafetyCheck()
	
	if addMeshModelOnStart and item:
		if  !item.dropped_item_model.is_empty():
			$Geometry/MeshInstance3D.queue_free()
			var path =  item.dropped_item_model
			var dropped_item = load(path)
			var obj:Node = dropped_item.instantiate()
			self.AddMeshModel(obj)
			itemModel = obj
			var animator: AnimationPlayer = $AnimationPlayer
			if animator:
				if animator.has_animation("ItemIdle"):
					animator.play("ItemIdle")
					
func AddMeshModel(model):
	$Geometry.add_child(model)

func itemSafetyCheck():
	if quantityCounter:
		if !quantityCounter.item and item:
			quantityCounter.item = item
		elif !quantityCounter.item and !item:
			print("Pickup Item with no item attempting to initialise, Name: " + name + ". cords:" 
			+ " X:" + str(transform.basis.x) 
			+ " Y:" + str(transform.basis.y) 
			+ " Z:" + str(transform.basis.z))
			queue_free()
		else:
			item = quantityCounter.item
	elif !quantityCounter and item:
		quantityCounter = QuantitySlot.new()
		quantityCounter.item = item
		quantityCounter.quantity = amount
	elif (!quantityCounter and !item) or (!quantityCounter.item and !item):
		print("Pickup Item with no item attempting to initialise, Name: " + name + ". cords:" 
		+ " X:" + str(transform.basis.x) 
		+ " Y:" + str(transform.basis.y) 
		+ " Z:" + str(transform.basis.z))
		queue_free()

func _apply_color():
	if not item or not itemModel:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = item.get_type_color()
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.6
	itemModel.set_surface_override_material(0, mat)

func Collect(player):
	if toBeDeleted:
		return false
	toBeDeleted = true
	
	$AnimationPlayer.stop()
	
	player.pickup_item_quantiy(quantityCounter)
	
	is_pickable = false
	queue_free()
	return true
