extends Node3D

## main.gd — wires up scene-node enemies/player and spawns world pickups.
## All geometry, lighting, the player, and enemies live in main.tscn.
## Item stats are defined in res://resources/items/*.tres — edit there, not here.

@onready var _player: Player  = $Player
@onready var _enemies: Node3D = $Enemies

#region Item pools

const _WEAPONS: Array[String] = [
	"res://resources/items/pistol.tres",
	"res://resources/items/assault_rifle.tres",
	"res://resources/items/shotgun.tres",
	"res://resources/items/sniper_rifle.tres",
]
const _ARMORS: Array[String] = [
	"res://resources/items/light_armor.tres",
	"res://resources/items/heavy_armor.tres",
]
const _ACCESSORIES: Array[String] = [
	"res://resources/items/speed_boots.tres",
	"res://resources/items/power_glove.tres",
	"res://resources/items/medic_ring.tres",
]
const _MEDKIT  := "res://resources/items/medkit.tres"
const _GRENADE := "res://resources/items/grenade.tres"

#endregion

func _ready():
	_player.player_died.connect(_on_player_died)

	for enemy: Enemy in _enemies.get_children():
		enemy.enemy_died.connect(_on_enemy_died)
		var tier := randi() % 3
		_apply_tier(enemy, tier)
		enemy.drop_table = _make_drop_table(tier)

#region Enemy tier setup

func _apply_tier(enemy: Enemy, tier: int):
	match tier:
		1:
			enemy.max_health    = 80.0
			enemy.attack_damage = 14.0
			enemy.move_speed    = 4.0
		2:
			enemy.max_health      = 120.0
			enemy.attack_damage   = 18.0
			enemy.move_speed      = 4.5
			enemy.detection_range = 22.0

func _make_drop_table(tier: int) -> Array[ItemData]:
	var table: Array[ItemData] = []
	match tier:
		0:
			if randf() < 0.6:
				table.append(_load(_WEAPONS[randi() % _WEAPONS.size()]))
			if randf() < 0.5:
				table.append(_load(_MEDKIT))
		1:
			table.append(_load(_WEAPONS[randi() % _WEAPONS.size()]))
			if randf() < 0.4:
				table.append(_load(_ARMORS[0]))
			if randf() < 0.4:
				table.append(_load(_MEDKIT))
		2:
			table.append(_load(_WEAPONS[randi() % _WEAPONS.size()]))
			table.append(_load(_ARMORS[1]))
			if randf() < 0.5:
				table.append(_load(_ACCESSORIES[randi() % _ACCESSORIES.size()]))
			if randf() < 0.35:
				table.append(_load(_GRENADE))
	return table

## Load a .tres and return a duplicate so each drop is an independent instance.
func _load(path: String) -> ItemData:
	return ResourceLoader.load(path).duplicate()

#endregion

#region Callbacks

func _on_enemy_died(_drop_pos: Vector3):
	if _player and is_instance_valid(_player):
		_player.add_score(100)
		_player.add_kill()

func _on_player_died():
	print("Game over. Final score: ", _player._score if _player else 0)

#endregion
