@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends AttackComponent
class_name MeleeAttackComponent

func _ready() -> void:
	attack_damage = 10.0
	attack_range = 2.2
	attack_enabled = true

func executeAttack(_Muzzles: Array[Marker3D]) -> void:
	if target:
		target.health_component.take_damage(attack_damage)
	# Lunge visual: quick position shift
	var original: Vector3 = attacker.global_position
	var tween: Tween = create_tween()
	var lunge_pos: Vector3 = attacker.global_position + (-attacker.global_transform.basis.z) * 0.4
	tween.tween_property(self, "global_position", lunge_pos, 0.07)
	tween.tween_property(self, "global_position", original, 0.12)
