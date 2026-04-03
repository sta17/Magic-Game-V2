@tool
extends AbilityData
class_name MeleeAbility

## Active ability: strike enemies within melee range in front of the player.
## No ammo, no reload — just a cooldown.

@export var damage:       float = 40.0
@export var attack_range: float = 2.5
@export var cooldown_sec: float = 0.7

var _last_use_ms: int = -999999

func _init() -> void:
	slot_name = "Melee Strike"
	description  = "Deal %d damage to enemies within %.1fm. No ammo needed." % [int(damage), attack_range]

func execute(_player: Player) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_use_ms < int(cooldown_sec * 1000):
		return
	_last_use_ms = now

	var forward: Vector3 = -_player.global_transform.basis.z
	var hit_any := false

	for enemy in _player.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector3 = enemy.global_position - _player.global_position
		# Must be within range and roughly in front (within ~73°)
		if to_enemy.length() <= attack_range and to_enemy.normalized().dot(forward) > 0.3:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hit_any = true

	if hit_any:
		_player._hud.show_notif("Melee hit! -%d" % int(damage), Color(1.0, 0.45, 0.1))
	else:
		_player._hud.show_notif("No enemies in range.", Color(0.55, 0.55, 0.55))

func get_type_color() -> Color:
	return Color(1.0, 0.45, 0.1)
