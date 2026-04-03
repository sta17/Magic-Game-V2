@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends RigidBody3D
class_name GrenadeProjectile

const _GrenadeVFX  := preload("res://Scenes/grenade_projectile_vfx.tscn")

@export var damage: float = 80.0
@export var radius: float = 5.0
@export var fuse_time: float = 1.5

var _timer: float = 0.0
var _exploded: bool = false

func _process(delta: float) -> void:
	if _exploded:
		return
	_timer += delta
	if _timer >= fuse_time:
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
	var vfx: GrenadeProjectileVFX = _GrenadeVFX.instantiate()
	vfx.radius = radius
	vfx._startVFX()

	get_tree().current_scene.add_child(vfx)
	vfx.global_position = global_position
