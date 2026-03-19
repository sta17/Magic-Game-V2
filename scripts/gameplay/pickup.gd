extends Area3D
class_name Pickup

signal picked_up(item: ItemData)

## Assign in the Inspector or via scene; each pickup duplicates it on _ready
## so pickups referencing the same .tres never share mutable state (ammo etc.)
@export var item_data: ItemData = null

var _bob_base_y: float = 0.0
var _time: float = 0.0

@onready var mesh_inst: MeshInstance3D  = $MeshInstance3D
@onready var label3d: Label3D           = $Label3D

func _ready():
	# Duplicate so multiple pickups using the same .tres don't share ammo state
	if item_data:
		item_data = item_data.duplicate()
	_bob_base_y = global_position.y

	if label3d and item_data:
		label3d.text = "[E]  " + item_data.item_name
		label3d.modulate = item_data.get_type_color()
	if label3d:
		label3d.visible = false

	_apply_color()

func _process(delta: float):
	_time += delta
	# Bob and spin
	global_position.y = _bob_base_y + sin(_time * 2.2) * 0.15
	rotate_y(delta * 1.4)

func show_label(visible: bool) -> void:
	if label3d:
		label3d.visible = visible

func _apply_color():
	if not item_data or not mesh_inst:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = item_data.get_type_color()
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.6
	mesh_inst.set_surface_override_material(0, mat)

## Called by Player when pressing interact
func try_pickup(picker: Node) -> bool:
	if not item_data:
		return false
	if not picker.has_method("pickup_item"):
		return false
	if picker.pickup_item(item_data):
		picked_up.emit(item_data)
		queue_free()
		return true
	return false
