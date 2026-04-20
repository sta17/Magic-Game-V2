@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_money_bag.png")
extends Area3D
class_name PickUpItem

@export var item : ItemData
@export var quantityCounter : QuantitySlot
@export var is_pickable := true
@export var autoCollect := false
@export var autoUse:= false
@export var amount : int = 1
@export var addMeshModelOnStart : bool = true

@onready var label3d: Label3D	= $Label3D
@onready var geometry: Node3D	= $Geometry
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var editor_Model: MeshInstance3D = $Geometry/editor_Model

var itemModel: Node3D
var toBeDeleted:bool = false

func _ready() -> void:
	_setup()

func _setup() -> void:
	itemSafetyCheck()
	
	if addMeshModelOnStart and item:
		if  !item.dropped_item_model == null:
			editor_Model.queue_free()
			var obj:Node = item.dropped_item_model.instantiate()
			geometry.add_child(obj)
			self.position.y = self.position.y + 1.0
			itemModel = obj
			if animator:
				if animator.has_animation("ItemIdle"):
					animator.play("ItemIdle")
					
	if label3d and item:
		label3d.text = "[" + button_name("interact") + "]  " + item.getName()
		label3d.modulate = item.get_type_color()
	if label3d:
		label3d.visible = false

func button_name(action_name: String) -> String:
	var button_events_name:String = str(InputMap.action_get_events(action_name))
	return button_events_name.get_slice(":",1).get_slice(",",0).get_slice("(",1).get_slice(")",0)

func AddMeshModel(model:Node) -> void:
	geometry.add_child(model)

func itemSafetyCheck() -> void:
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

func show_label(new_visible: bool) -> void:
	if label3d:
		label3d.visible = new_visible

func _apply_color() -> void:
	if not item or not itemModel:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = item.get_type_color()
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.6
	itemModel.set_surface_override_material(0, mat)

func Collect(player:Player) -> bool:
	if toBeDeleted:
		return false
	toBeDeleted = true
	
	animator.stop()
	
	player.pickup_item_quantiy(quantityCounter,autoUse)
	
	is_pickable = false
	queue_free()
	return true
