@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_skull.png")
extends StaticBody3D
class_name EnemyStaticRotating

enum State { IDLE, PATROL, CHASE, DEAD, STAND, ATTACK }

@export var max_health: float      = 50.0
@export var move_speed: float      = 0.8
@export var state: State = State.IDLE
@export var melee_attack_damage: float   = 10.0
@export var ranged_attack_damage: float   = 20.0
@export var melee_attack_range: float    = 2.2
@export var ranged_attack_range: float    = 4.4
@export var attack_cooldown: float = 0.2#1.2
@export var drop_table: Array[ItemData] = []
@export var _ranged_icon: Texture2D
@export var _melee_icon: Texture2D
@export var patrol_radius: float   = 8.0

var health: float
var _spawn_pos: Vector3
var _player: Node3D      = null
var _patrol_target: Vector3
var _patrol_wait: float  = 0.0

const _PickupScene := preload("res://Scenes/PickUpItem.tscn")
const _BulletScene  := preload("res://Scenes/bullet.tscn")

var _attack_timer: float = 0.0

# Visuals — nodes come from enemy.tscn, visible in the editor
@onready var _head_icon:	Sprite3D		= $HeadIcon
@onready var _center:		Marker3D		= $Marker3D
@onready var _hp_bar:		Health_Bar		= $HealthBar
@onready var _enemy_attack:	Enemy_Attack	= $RotationPoint/Muzzles/EnemyAttack
@onready var _MuzzleA:		Marker3D		= $RotationPoint/Muzzles/MuzzleA
@onready var _MuzzleB:		Marker3D		= $RotationPoint/Muzzles/MuzzleB
@onready var rotationPoint: Node3D			= $RotationPoint
@onready var dmgParticles: CPUParticles3D	= $CPUParticles3D

signal creature_died(drop_position: Vector3)

func _ready() -> void:
	add_to_group("npc")
	health = max_health
	_spawn_pos     = global_position
	call_deferred("_find_player")
	call_deferred("_setup_hp_sprite")
	_enemy_attack.attacker = self
	_enemy_attack.melee_attack_damage = melee_attack_damage
	_enemy_attack.ranged_attack_damage = ranged_attack_damage
	_enemy_attack.detection_range = ranged_attack_range

func _setup_hp_sprite() -> void:
	_hp_bar._setup_hp_sprite(health,max_health)

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_attack_timer -= delta

	match state:
		State.IDLE:		_do_idle(delta)
		State.PATROL:	_do_patrol(delta)
		State.CHASE:	_do_chase(delta)
		State.ATTACK:	_do_attack(delta)
		State.STAND:	_do_stand(delta)

func _do_stand(_delta: float) -> void:
	# Stand Still and Do Nothing
	pass

func _do_idle(delta: float) -> void:
	_patrol_wait += delta
	if _patrol_wait > 2.0:
		_patrol_wait = 0.0
		state = State.PATROL
	if _enemy_attack._check_detect():
		state = State.CHASE

func _do_attack(delta: float) -> void:
	if not _player:
		state = State.PATROL; return
	var dist:float = global_position.distance_to(_player.global_position)
	if dist > ranged_attack_range * 1.3:
		state = State.PATROL; return

	_face_target(_player.global_position, delta * (move_speed/2))

	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		if (dist <= ranged_attack_range) and (dist > melee_attack_range):
			_do_ranged_attack()
		elif (dist <= melee_attack_range) and dist >= 0:
			#_do_melee_attack()
			_do_ranged_attack()

func _do_melee_attack() -> void:
	_head_icon.texture = _melee_icon
	_enemy_attack._do_melee_attack()

func _do_ranged_attack() -> void:
	_head_icon.texture = _ranged_icon
	_enemy_attack._do_ranged_attack(_MuzzleA)
	_enemy_attack._do_ranged_attack(_MuzzleB)

func _do_chase(_delta: float) -> void:
	if not _player:
		state = State.PATROL; return
	var dist:float = global_position.distance_to(_player.global_position)
	if dist >= ranged_attack_range:
		_patrol_target = _player.position;
		state = State.PATROL; return
	if dist <= ranged_attack_range or dist <= melee_attack_range:
		_patrol_target = _player.position;
		state = State.ATTACK; return

func _do_patrol(delta: float) -> void:
	if _enemy_attack._check_detect():
		state = State.CHASE
	elif state == State.PATROL:
		_patrol_wait += delta
		if _patrol_wait > 2.0:
			_patrol_wait = 0.0
			_set_patrol_target()
			state = State.IDLE
			return
		_face_target(_patrol_target, delta * move_speed)

func _set_patrol_target() -> void:
	var offset: Vector3 = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0.0,
		randf_range(-patrol_radius, patrol_radius)
	)
	_patrol_target = _spawn_pos + offset

func _face_target(target: Vector3, weight: float) -> void:
	var dir: Vector3 = (target - rotationPoint.global_position)
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var target_angle:float = atan2(dir.x, dir.z)
	rotationPoint.rotation.y = lerp_angle(rotationPoint.rotation.y, target_angle, weight)

func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	_hp_bar._update_health_bar(-amount)
	if _hp_bar._is_damaged():
		dmgParticles.emitting = true
	if state == State.PATROL or state == State.IDLE:
		state = State.CHASE
	if _hp_bar._is_dead():
		_die()

func _die() -> void:
	state = State.DEAD
	dmgParticles.emitting = false
	
	dmgParticles.queue_free()
	
	creature_died.emit(global_position)
	self.queue_free()

func getCenter() -> Marker3D:
	return _center
