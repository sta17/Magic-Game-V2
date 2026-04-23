@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends Node3D
class_name AttackComponent

signal attack_ready
signal attack_cooldown_start

const _BulletScene  := preload("res://Scenes/bullet.tscn")

@export_category("Nodes")
@export var target: Node3D = null
@export var attacker: Node3D = null

@export_category("Stats")
@export var attack_cooldown: float = 1.2
@export var attack_timer: float = 0.0
@export var attack_damage: float   = 10.0
@export var attack_range: float    = 2.2
@export var attack_enabled: bool    = true
@export var detection_range: float = 16.0
@export var is_attack_ready: bool = true

func _physics_process(delta: float) -> void:
	if not is_attack_ready:
		attack_timer -= delta
	
		if attack_timer <= 0.0:
			is_attack_ready = true
			attack_ready.emit()

func setTarget(newTarget:Node3D) -> void:
	target = newTarget

func _do_attack(_Muzzles: Array[Marker3D]) -> void:
	if not attack_enabled: return

	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		attack_cooldown_start.emit()
		is_attack_ready = false
		if is_in_range:
			executeAttack(_Muzzles)

func is_in_range() -> bool:
	var dist:float = global_position.distance_to(target.global_position)
	if (dist <= attack_range * 1.3) and dist >= 0:
		return true
	return false

func can_attack() -> bool:
	return is_in_range() and attack_enabled and is_attack_ready
	
func executeAttack(_Muzzles: Array[Marker3D]) -> void:
	pass
