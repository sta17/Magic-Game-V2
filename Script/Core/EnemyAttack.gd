@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends Node3D
class_name Enemy_Attack

const _BulletScene  := preload("res://Scenes/bullet.tscn")

@export var _player: Node3D = null
@export var attacker: Node3D = null
@export var bullet_speed: float = 20.0
@export var melee_attack_damage: float   = 10.0
@export var ranged_attack_damage: float   = 20.0
@export var detection_range: float = 16.0

func _ready() -> void:
	call_deferred("_find_player")

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _do_ranged_attack(_Muzzle: Marker3D) -> void:
	var bullet: Bullet = _BulletScene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var dir: Vector3 = (_Muzzle.global_transform.basis.z).normalized()

	bullet.position = _Muzzle.global_position
	bullet.transform.basis = _Muzzle.global_transform.basis
	bullet.direction = dir
	bullet.speed     = bullet_speed
	bullet.damage    = ranged_attack_damage
	bullet.shooter   = attacker

func _do_melee_attack() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(melee_attack_damage)
	# Lunge visual: quick position shift
	var original: Vector3 = attacker.global_position
	var tween: Tween = create_tween()
	var lunge_pos: Vector3 = attacker.global_position + (-attacker.global_transform.basis.z) * 0.4
	tween.tween_property(self, "global_position", lunge_pos, 0.07)
	tween.tween_property(self, "global_position", original, 0.12)
	
func _check_detect() -> bool:
	if not _player:
		return false
	if attacker.global_position.distance_to(_player.global_position) <= detection_range:
		return true
	return false
