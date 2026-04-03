@tool
extends AbilityData
class_name EnergyBoltAbility

## Active ability: fire an energy projectile. No ammo, no reload — just a cooldown.

@export var damage:       float = 45.0
@export var speed:        float = 28.0
@export var cooldown_sec: float = 0.6

const _BulletScene := preload("res://scenes/bullet.tscn")

var _last_use_ms: int = -999999

func _init() -> void:
	slot_name = "Energy Bolt"
	description  = "Fire a bolt dealing %d damage." % int(damage)

func execute(_player: Player) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_use_ms < int(cooldown_sec * 1000):
		return
	_last_use_ms = now

	var bullet: Bullet = _BulletScene.instantiate()
	_player.get_tree().current_scene.add_child(bullet)

	var dir: Vector3 = -_player._muzzle.global_transform.basis.z
	bullet.global_position = _player._muzzle.global_position
	bullet.direction       = dir
	bullet.speed           = speed
	bullet.damage          = damage
	bullet.shooter         = _player

func get_type_color() -> Color:
	return Color(0.2, 0.7, 1.0)
