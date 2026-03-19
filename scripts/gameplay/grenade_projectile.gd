extends RigidBody3D
class_name GrenadeProjectile

var damage: float = 80.0
var radius: float = 5.0

const FUSE_TIME: float = 2.5

var _timer: float = 0.0
var _exploded: bool = false

func _ready() -> void:
	# Mesh
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.14
	sphere.height = 0.28
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.75, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.75, 0.15)
	mat.emission_energy_multiplier = 0.6
	mesh_inst.set_surface_override_material(0, mat)
	add_child(mesh_inst)

	# Collision
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.14
	col.shape = shape
	add_child(col)

func _process(delta: float) -> void:
	if _exploded:
		return
	_timer += delta
	if _timer >= FUSE_TIME:
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	# Damage all enemies in radius
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= radius and enemy.has_method("take_damage"):
			var falloff := 1.0 - clampf(dist / radius, 0.0, 1.0)
			enemy.take_damage(damage * falloff)

	_spawn_explosion_vfx()
	queue_free()

func _spawn_explosion_vfx() -> void:
	var vfx := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	vfx.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.1, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.05)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vfx.set_surface_override_material(0, mat)
	vfx.global_position = global_position
	get_tree().current_scene.add_child(vfx)

	var target_scale := Vector3.ONE * radius * 2.0
	var tween := vfx.create_tween()
	tween.tween_property(vfx, "scale", target_scale, 0.35)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.tween_callback(vfx.queue_free)
