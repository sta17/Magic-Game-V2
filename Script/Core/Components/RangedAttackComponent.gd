@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends AttackComponent
class_name RangedAttackComponent

@export_category("Stats")
@export var bullet_speed: float = 20.0
@export var bulletScene := preload("res://Scenes/bullet.tscn")

func _ready() -> void:
	attack_damage = 20.0
	attack_range = 4.4
	attack_enabled = true

func is_in_range() -> bool:
	var dist:float = global_position.distance_to(target.global_position)
	if (dist <= attack_range * 1.3) and (dist > attack_range * 1.3):
		return true
	return false

func executeAttack(_Muzzles: Array[Marker3D]) -> void:
	
	for muzzle in _Muzzles:
		var bullet: Bullet = _BulletScene.instantiate()
		get_tree().current_scene.add_child(bullet)

		var dir: Vector3 = (muzzle.global_transform.basis.z).normalized()

		bullet.position = muzzle.global_position
		bullet.transform.basis = muzzle.global_transform.basis
		bullet.direction = dir
		bullet.speed     = bullet_speed
		bullet.damage    = attack_damage
		bullet.shooter   = attacker
