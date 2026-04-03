@tool
@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends AbilityData
class_name PowerPunchAbility

const _GrenadeVFX  := preload("res://Scenes/grenade_projectile_vfx.tscn")

@export var damage:			float = 80.0
@export var radius:			float = 5.0

func _init() -> void:
	slot_name = "Power Punch"
	description  = "Damage: %d   Up to distance in front: %.0f m   " % [int(damage), radius*2]

func execute(player: Player) -> void:
	var vfx: GrenadeProjectileVFX = _GrenadeVFX.instantiate()
	vfx.radius = radius
	
	# Damage all enemies in radius
	var pos_in_front: Vector3 = player.global_transform.origin + (Vector3.FORWARD * radius)
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector3 = enemy.global_position - pos_in_front
		# Must be within range and roughly in front (within ~73°)
		var dist : float = pos_in_front.distance_to(enemy.global_position)
		if to_enemy.length() <= radius and enemy.has_method("take_damage"):
			var falloff := 1.0 - clampf(dist / radius, 0.0, 1.0)
			enemy.take_damage(damage * falloff)

	player.get_tree().current_scene.add_child(vfx)
	vfx.global_position = pos_in_front
	vfx._startVFX()
