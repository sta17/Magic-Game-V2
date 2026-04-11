extends CharacterBody3D
class_name NPC

enum State { IDLE, PATROL, CHASE, DEAD, STAND, ATTACK }

@export var move_speed: float      = 3.5
@export var detection_range: float = 16.0
@export var patrol_radius: float   = 8.0
@export var _overhead_icon: Texture2D
@export var state: State = State.STAND
@export var interactable:bool = false
@export var GRAVITY:		float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var interact_script: DialogScript

var _spawn_pos: Vector3
var _patrol_target: Vector3
var _patrol_wait: float  = 0.0
var _player: Node3D      = null

# Visuals — nodes come from enemy.tscn, visible in the editor
@onready var _head_icon:	Sprite3D		= $HeadIcon
@onready var _center:		Marker3D		= $Marker3D

signal creature_died(drop_position: Vector3)

func _ready() -> void:
	add_to_group("npc")
	_spawn_pos     = global_position
	_patrol_target = global_position
	if state == State.PATROL:
		call_deferred("_find_player")
	if !_overhead_icon:
		_head_icon.texture = null
		_head_icon.visible = false
	
func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y += (GRAVITY * -1) * delta

	match state:
		State.IDLE:		_do_idle(delta)
		State.PATROL:	_do_patrol(delta)
		State.CHASE:	_do_chase(delta)
		State.STAND:	_do_stand(delta)

	move_and_slide()

func interact(player: Player) -> void:
	player._chat_window(self)

func _do_stand(_delta: float) -> void:
	# Stand Still and Do Nothing
	pass

func _do_idle(delta: float) -> void:
	velocity.x = 0.0; velocity.z = 0.0
	_patrol_wait += delta
	if _patrol_wait > 2.0:
		_patrol_wait = 0.0
		state = State.PATROL

func _do_patrol(delta: float) -> void:
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
	_move_toward(_player.global_position, move_speed, delta)

func _move_toward(target: Vector3, speed: float, delta: float) -> void:
	var flat_dir: Vector3 = (target - global_position)
	flat_dir.y = 0.0
	if flat_dir.length() < 0.01:
		velocity.x = 0.0; velocity.z = 0.0
		return
	flat_dir = flat_dir.normalized()
	velocity.x = flat_dir.x * speed
	velocity.z = flat_dir.z * speed
	_face_target(target, delta * 6.0)

func _face_target(target: Vector3, weight: float) -> void:
	var dir: Vector3 = (target - global_position)
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var target_angle:float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, weight)

func _set_patrol_target() -> void:
	var offset: Vector3 = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0.0,
		randf_range(-patrol_radius, patrol_radius)
	)
	_patrol_target = _spawn_pos + offset

func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO

	# Flash red then fade
	#@onready var _mesh:			MeshInstance3D	= $MeshInstance3D
	#if _mesh:
	#	var mat: StandardMaterial3D = StandardMaterial3D.new()
	#	mat.albedo_color = Color(0.6, 0.0, 0.0)
	#	_mesh.set_surface_override_material(0, mat)

	creature_died.emit(global_position)

	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(queue_free)

func getCenter() -> Marker3D:
	return _center
