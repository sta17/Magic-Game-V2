extends CharacterBody3D
class_name Enemy

enum State { IDLE, PATROL, CHASE, ATTACK, DEAD }

@export var max_health: float      = 50.0
@export var move_speed: float      = 3.5
@export var attack_damage: float   = 10.0
@export var attack_range: float    = 2.2
@export var detection_range: float = 16.0
@export var attack_cooldown: float = 1.2
@export var patrol_radius: float   = 8.0
@export var drop_table: Array[ItemData] = []

const GRAVITY:      float = -9.8
const DROP_CHANCE:  float = 0.6

const _PickupScene := preload("res://Scenes/PickUpItem.tscn")

var health: float
var state: State = State.PATROL
var _spawn_pos: Vector3
var _patrol_target: Vector3
var _attack_timer: float = 0.0
var _patrol_wait: float  = 0.0
var _player: Node3D      = null

# Visuals — nodes come from enemy.tscn, visible in the editor
@onready var _mesh:        MeshInstance3D = $MeshInstance3D
@onready var _hp_viewport: SubViewport = $HealthBar/HPViewport
@onready var _hp_bar:      ProgressBar = $HealthBar/HPViewport/ProgressBar
@onready var _hp_sprite:   Sprite3D    = $HealthBar/HPSprite

signal enemy_died(drop_position: Vector3)

func _ready():
	add_to_group("enemy")
	health = max_health
	_spawn_pos     = global_position
	_patrol_target = global_position
	call_deferred("_find_player")
	call_deferred("_setup_hp_sprite")

func _find_player():
	_player = get_tree().get_first_node_in_group("player")

func _setup_hp_sprite():
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_hp_sprite.texture = _hp_viewport.get_texture()

func _physics_process(delta: float):
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_attack_timer -= delta

	match state:
		State.IDLE:   _do_idle(delta)
		State.PATROL: _do_patrol(delta)
		State.CHASE:  _do_chase(delta)
		State.ATTACK: _do_attack(delta)

	move_and_slide()

func _do_idle(delta: float):
	velocity.x = 0.0; velocity.z = 0.0
	_patrol_wait += delta
	if _patrol_wait > 2.0:
		_patrol_wait = 0.0
		state = State.PATROL
	_check_detect()

func _do_patrol(delta: float):
	_check_detect()
	var dist_to_target = global_position.distance_to(_patrol_target)
	if dist_to_target < 0.8:
		_set_patrol_target()
		state = State.IDLE
		return
	_move_toward(_patrol_target, move_speed * 0.6, delta)

func _do_chase(delta: float):
	if not _player:
		state = State.PATROL; return
	var dist = global_position.distance_to(_player.global_position)
	if dist > detection_range * 1.6:
		state = State.PATROL; return
	if dist <= attack_range:
		state = State.ATTACK; return
	_move_toward(_player.global_position, move_speed, delta)

func _do_attack(delta: float):
	if not _player:
		state = State.PATROL; return
	var dist = global_position.distance_to(_player.global_position)
	if dist > attack_range * 1.3:
		state = State.CHASE; return

	velocity.x = 0.0; velocity.z = 0.0
	_face_target(_player.global_position, delta * 8.0)

	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_do_melee_hit()

func _move_toward(target: Vector3, speed: float, delta: float):
	var flat_dir = (target - global_position)
	flat_dir.y = 0.0
	if flat_dir.length() < 0.01:
		velocity.x = 0.0; velocity.z = 0.0
		return
	flat_dir = flat_dir.normalized()
	velocity.x = flat_dir.x * speed
	velocity.z = flat_dir.z * speed
	_face_target(target, delta * 6.0)

func _face_target(target: Vector3, weight: float):
	var dir = (target - global_position)
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var target_angle = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, weight)

func _check_detect():
	if not _player:
		return
	if global_position.distance_to(_player.global_position) <= detection_range:
		state = State.CHASE

func _set_patrol_target():
	var offset = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0.0,
		randf_range(-patrol_radius, patrol_radius)
	)
	_patrol_target = _spawn_pos + offset

func _do_melee_hit():
	if _player and _player.has_method("take_damage"):
		_player.take_damage(attack_damage)
	# Lunge visual: quick position shift
	var original = global_position
	var tween = create_tween()
	var lunge_pos = global_position + (-global_transform.basis.z) * 0.4
	tween.tween_property(self, "global_position", lunge_pos, 0.07)
	tween.tween_property(self, "global_position", original, 0.12)

func take_damage(amount: float):
	if state == State.DEAD:
		return
	health -= amount
	_update_health_bar()
	_spawn_damage_number(amount)
	if state == State.PATROL or state == State.IDLE:
		state = State.CHASE
	if health <= 0.0:
		_die()

func _spawn_damage_number(amount: float) -> void:
	var label := Label3D.new()
	label.text = "-%d" % int(amount)
	label.font_size = 48
	label.modulate = Color(1.0, 0.3, 0.1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector3(0, 2.4, 0)
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 1.2, 0), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free).set_delay(0.8)

func _update_health_bar():
	if not _hp_bar:
		return
	_hp_bar.value = (health / max_health) * 100.0

func _die():
	state = State.DEAD
	velocity = Vector3.ZERO

	# Flash red then fade
	if _mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.0, 0.0)
		_mesh.set_surface_override_material(0, mat)

	enemy_died.emit(global_position)
	_try_drop_items()

	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(queue_free)

func _try_drop_items():
	for item in drop_table:
		if randf() < DROP_CHANCE:
			_spawn_pickup(item.duplicate(true))

func _spawn_pickup(item: ItemData):
	var pickup: PickUpItem = _PickupScene.instantiate()
	pickup.item_data = item
	# Set position BEFORE add_child so _ready() captures the correct bob base Y
	pickup.position = global_position + Vector3(
		randf_range(-0.6, 0.6), 0.8, randf_range(-0.6, 0.6)
	)
	get_tree().current_scene.add_child(pickup)
