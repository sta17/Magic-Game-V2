@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_skull.png")
extends NPC
class_name Enemy

@export var max_health: float      = 50.0
@export var melee_attack_damage: float   = 10.0
@export var ranged_attack_damage: float   = 20.0
@export var melee_attack_range: float    = 2.2
@export var ranged_attack_range: float    = 4.4
@export var attack_cooldown: float = 1.2
@export var drop_table: Array[ItemData] = []
@export var bullet_speed: float = 20.0
@export var _ranged_icon: Texture2D
@export var _melee_icon: Texture2D

const DROP_CHANCE:  float = 0.6

const _PickupScene := preload("res://Scenes/PickUpItem.tscn")
const _BulletScene  := preload("res://Scenes/bullet.tscn")

var health: float
var _attack_timer: float = 0.0

# Visuals — nodes come from enemy.tscn, visible in the editor
@onready var _mesh:			MeshInstance3D	= $MeshInstance3D2
@onready var _muzzle:		Marker3D		= $Marker3D
@onready var _hp_bar:		Health_Bar		= $HealthBar
@onready var _enemy_attack:	Enemy_Attack	= $EnemyAttack

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	_spawn_pos     = global_position
	_patrol_target = global_position
	call_deferred("_find_player")
	call_deferred("_setup_hp_sprite")
	
	_enemy_attack.attacker = self
	_enemy_attack.melee_attack_damage = melee_attack_damage
	_enemy_attack.ranged_attack_damage = ranged_attack_damage
	_enemy_attack.detection_range = detection_range

func _setup_hp_sprite() -> void:
	_hp_bar._setup_hp_sprite(health,max_health)

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_attack_timer -= delta

	match state:
		State.IDLE:		_do_idle(delta)
		State.PATROL:	_do_patrol(delta)
		State.CHASE:	_do_chase(delta)
		State.ATTACK:	_do_attack(delta)
		State.STAND:	super._do_stand(delta)

	move_and_slide()

func _do_idle(delta: float) -> void:
	super._do_idle(delta)
	if _enemy_attack._check_detect():
		state = State.CHASE

func _do_patrol(delta: float) -> void:
	if _enemy_attack._check_detect():
		state = State.CHASE
	elif state == State.PATROL:
		super._do_patrol(delta)

func _do_chase(delta: float) -> void:
	if not _player:
		state = State.PATROL; return
	var dist:float = global_position.distance_to(_player.global_position)
	if dist > detection_range * 1.6:
		state = State.PATROL; return
	if dist <= ranged_attack_range or dist <= melee_attack_range:
		state = State.ATTACK; 
		velocity.x = 0.0; velocity.z = 0.0
		return
	_move_toward(_player.global_position, move_speed, delta)

func _do_attack(delta: float) -> void:
	if not _player:
		state = State.PATROL; return
	var dist:float = global_position.distance_to(_player.global_position)
	if dist > ranged_attack_range * 1.3:
		state = State.CHASE; return

	_face_target(_player.global_position, delta * 8.0)

	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		if (dist <= ranged_attack_range * 1.3) and (dist > melee_attack_range * 1.3):
			_do_ranged_attack()
		elif (dist <= melee_attack_range * 1.3) and dist >= 0:
			_do_melee_attack()

func _do_melee_attack() -> void:
	_head_icon.texture = _melee_icon
	_enemy_attack._do_melee_attack()

func _do_ranged_attack() -> void:
	_head_icon.texture = _ranged_icon
	_enemy_attack._do_ranged_attack(_muzzle)

func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	_hp_bar._update_health_bar(-amount)
	if state == State.PATROL or state == State.IDLE:
		state = State.CHASE
	if _hp_bar._is_dead():
		_die()

func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO

	# Flash red then fade
	if _mesh:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.0, 0.0)
		_mesh.set_surface_override_material(0, mat)

	creature_died.emit(global_position)
	_try_drop_items()

	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(queue_free)

func _try_drop_items() -> void:
	for item in drop_table:
		if randf() < DROP_CHANCE:
			_spawn_pickup(item.duplicate(true))

func _spawn_pickup(item: ItemData) -> void:
	var pickup: PickUpItem = _PickupScene.instantiate()
	pickup.item = item
	# Set position BEFORE add_child so _ready() captures the correct bob base Y
	pickup.position = global_position + Vector3(
		randf_range(-0.6, 0.6), 0.8, randf_range(-0.6, 0.6)
	)
	get_tree().current_scene.add_child(pickup)
