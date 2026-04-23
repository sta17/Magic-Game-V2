@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_skull.png")
extends StaticBody3D
class_name EnemyStaticRotating

signal enemy_died(drop_position: Vector3)

enum State { IDLE, PATROL, CHASE, DEAD, STAND, ATTACK }

const DROP_CHANCE:  float = 0.6
const _PickupScene := preload("res://Scenes/PickUpItem.tscn")

@export_category("Components")
@export var health_component: HealthComponent
@export var ranged_attack_component: RangedAttackComponent
@export var detection_component: DetectionComponent
@export var drop_item_component: DropItemComponent

@export_category("Stats")
@export var rotation_speed: float = 0.8
@export var ranged_icon: Texture2D
@export var drop_table: Array[ItemData] = []
@export var patrol_radius: float   = 8.0
@export var state: State = State.IDLE:
	set(value):
		state = value
		if value == State.PATROL:
			_set_patrol_target()
			_patrol_wait = 0.0
		elif value == State.CHASE:
			setTarget()
		elif value == State.IDLE:
			_patrol_wait = 0.0

var _spawn_pos: Vector3
var _patrol_target: Vector3
var _patrol_wait: float  = 0.0
var current_target: Node3D = null

# Visuals — nodes come from enemy.tscn, visible in the editor
@onready var _head_icon:	Sprite3D		= $HeadIcon
@onready var _hp_bar:		Health_Bar		= $HealthBar
@onready var _MuzzleA:		Marker3D		= $RotationPoint/Muzzles/MuzzleA
@onready var _MuzzleB:		Marker3D		= $RotationPoint/Muzzles/MuzzleB
@onready var _mesh:			MeshInstance3D	= $RotationPoint/turret_top
@onready var rotationPoint: Node3D			= $RotationPoint
@onready var dmgParticles: CPUParticles3D	= $CPUParticles3D

func _ready() -> void:
	add_to_group("enemy")
	_spawn_pos     = global_position
	call_deferred("_setup_hp_sprite")

	health_component.zero_health.connect(_die)
	health_component.took_damage.connect(update_HP)
	
	ranged_attack_component.attacker = self
	ranged_attack_component.detection_range = detection_component.detection_range

func _setup_hp_sprite() -> void:
	_hp_bar._setup_hp_sprite(health_component.health,health_component._max_hp())

func update_HP(amount:float) -> void:
	if state == State.DEAD:
		return
	if state == State.PATROL or state == State.IDLE:
		state = State.CHASE
	_hp_bar._update_health_bar(amount)

func _physics_process(delta: float) -> void:
	if state == State.DEAD: return

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
	if detection_component._check_detect():
		state = State.CHASE; return
	if _patrol_wait > 2.0:
		state = State.PATROL; return

func _do_patrol(delta: float) -> void:
	if detection_component._check_detect():
		state = State.CHASE; return
	_patrol_wait += delta
	if _patrol_wait > 2.0:
		state = State.IDLE; return
	_face_target(_patrol_target, delta * rotation_speed)

func _do_chase(_delta: float) -> void:
	if not detection_component._check_detect():
		state = State.PATROL; return
	
	if ranged_attack_component.is_in_range():
		_patrol_target = current_target.position;
		state = State.ATTACK; return
	_face_target(current_target.global_position, _delta * rotation_speed)

func _do_attack(delta: float) -> void:
	if not ranged_attack_component.is_in_range():
		state = State.CHASE; return

	_face_target(current_target.global_position, delta * (rotation_speed/2))

	if(ranged_attack_component.can_attack()):
		ranged_attack_component._do_attack([_MuzzleA,_MuzzleB])
		_head_icon.texture = ranged_icon

func _die() -> void:
	state = State.DEAD
	dmgParticles.emitting = false
	
	# Flash red then fade
	if _mesh:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.0, 0.0)
		_mesh.set_surface_override_material(0, mat)
	
	dmgParticles.queue_free()
	
	enemy_died.emit(global_position)
	drop_item_component._try_drop_items()
	
	for n in self.get_children():
		self.remove_child(n)
		n.queue_free()
	self.queue_free()

func setTarget() -> void:
	current_target = detection_component.getTargets()[0]
	ranged_attack_component.setTarget(current_target)

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
