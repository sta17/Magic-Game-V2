@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_skull.png")
extends NPC
class_name Enemy

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

var _attack_timer: float = 0.0

# Visuals — nodes come from enemy.tscn, visible in the editor
@onready var _mesh:			MeshInstance3D	= $MeshInstance3D
@onready var _muzzle:		Marker3D		= $Marker3D
@onready var _hp_bar:		Health_Bar		= $HealthBar

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	_spawn_pos     = global_position
	_patrol_target = global_position
	call_deferred("_find_player")
	call_deferred("_setup_hp_sprite")

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
		State.STAND:	_do_stand(delta)
		State.WANDER:	_do_wander(delta)

	move_and_slide()

func _do_idle(delta: float) -> void:
	velocity.x = 0.0; velocity.z = 0.0
	_patrol_wait += delta
	if _patrol_wait > 2.0:
		_patrol_wait = 0.0
		state = State.PATROL
	_check_detect()

func _do_patrol(delta: float) -> void:
	_check_detect()
	var dist_to_target:float = global_position.distance_to(_patrol_target)
	if dist_to_target < 0.8:
		_set_patrol_target()
		state = State.IDLE
		return
	_move_toward(_patrol_target, move_speed * 0.6, delta)

func _do_chase(delta: float) -> void:
	if not _player:
		state = State.PATROL; return
	var dist:float = global_position.distance_to(_player.global_position)
	if dist > detection_range * 1.6:
		state = State.PATROL; return
	if dist <= melee_attack_range:
		state = State.ATTACK; return
	_move_toward(_player.global_position, move_speed, delta)

func _do_attack(delta: float) -> void:
	if not _player:
		state = State.PATROL; return
	var dist:float = global_position.distance_to(_player.global_position)
	if dist > ranged_attack_range * 1.3:
		state = State.CHASE; return

	velocity.x = 0.0; velocity.z = 0.0
	_face_target(_player.global_position, delta * 8.0)

	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		if dist < ranged_attack_range * 1.3:
			_head_icon.texture = _ranged_icon
			_do_ranged_attack()
		if dist < melee_attack_range * 1.3:
			_head_icon.texture = _melee_icon
			_do_melee_attack()

func _do_stand(_delta: float) -> void:
	# Stand Still and Do Nothing
	pass

func _do_wander(delta: float) -> void:
	var dist_to_target: float = global_position.distance_to(_patrol_target)
	if dist_to_target < 0.8:
		_set_patrol_target()
		state = State.IDLE
		return
	_move_toward(_patrol_target, move_speed * 0.6, delta)

func _check_detect() -> void:
	if not _player:
		return
	if global_position.distance_to(_player.global_position) <= detection_range:
		state = State.CHASE

func _do_ranged_attack() -> void:
	var bullet: Bullet = _BulletScene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var dir: Vector3 = (_muzzle.global_transform.basis.z).normalized()

	bullet.global_position = _muzzle.global_position
	bullet.direction = dir
	bullet.speed     = bullet_speed
	bullet.damage    = ranged_attack_damage
	bullet.shooter   = self

func _do_melee_attack() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(melee_attack_damage)
	# Lunge visual: quick position shift
	var original: Vector3 = global_position
	var tween: Tween = create_tween()
	var lunge_pos: Vector3 = global_position + (-global_transform.basis.z) * 0.4
	tween.tween_property(self, "global_position", lunge_pos, 0.07)
	tween.tween_property(self, "global_position", original, 0.12)

func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	_hp_bar._update_health_bar(-amount)
	_spawn_damage_number(amount)
	if state == State.PATROL or state == State.IDLE:
		state = State.CHASE
	if _hp_bar._is_dead():
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
