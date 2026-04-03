@tool
@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends AbilityData
class_name GrenadeAbility

const _Grenade  := preload("res://Scenes/grenade_projectile.tscn")

@export var damage:			float = 80.0
@export var radius:			float = 5.0
@export var fuse_time:		float = 1.5
@export var throw_speed:	float = 14.0

func _init() -> void:
	slot_name = "Grenade"
	description  = "Damage: %d   Radius: %.0f m   Throw Speed: %.0f" % [int(damage), radius, throw_speed]

func execute(player) -> void:
	var grenade : GrenadeProjectile = _Grenade.instantiate()
	grenade.damage = damage
	grenade.radius = radius
	grenade.fuse_time = fuse_time
	player.get_tree().current_scene.add_child(grenade)
	grenade.global_position = player._muzzle.global_position + (-player._muzzle.global_transform.basis.z * 0.8)
	var dir : Vector3 = -player._muzzle.global_transform.basis.z + Vector3(0, 0.18, 0)
	grenade.linear_velocity = dir.normalized() * throw_speed
