@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_skull.png")
extends CharacterBody3D
class_name Enemy

signal enemy_died(drop_position: Vector3)

enum State { IDLE, PATROL, CHASE, DEAD, STAND, ATTACK }

@export_category("Components")
@export var health_component: HealthComponent
@export var melee_attack_component: MeleeAttackComponent
@export var ranged_attack_component: RangedAttackComponent
@export var detection_component: DetectionComponent
@export var drop_item_component: DropItemComponent
@export var movement_component: MovementComponent
@export var hitbox_component: HitboxComponent

@export_category("Stats")
@export var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var move_speed: float = 3.5
@export var melee_icon: Texture2D
@export var ranged_icon: Texture2D
@export var patrol_radius: float = 8.0
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
@onready var _mesh:			MeshInstance3D	= $MeshInstance3D2
@onready var _muzzle:		Marker3D		= $Marker3D
@onready var _hp_bar:		Health_Bar		= $HealthBar

func _ready() -> void:
	add_to_group("enemy")
	_spawn_pos     = global_position
	call_deferred("_setup_hp_sprite")

	health_component.zero_health.connect(_die)
	health_component.took_damage.connect(update_HP)
	
	detection_component.detection_enabled = true
	hitbox_component.detection_enabled = true
	hitbox_component.damage_source_hit.connect(health_component.incoming_damage)
	melee_attack_component.attacker = self
	melee_attack_component.detection_range = detection_component.detection_range
	ranged_attack_component.attacker = self
	ranged_attack_component.detection_range = detection_component.detection_range
	movement_component.movementPoint = self

func _setup_hp_sprite() -> void:
	_hp_bar._setup_hp_sprite(health_component.health,health_component._max_hp())

func update_HP(amount:float) -> void:
	if state == State.DEAD: return
	if state == State.PATROL or state == State.IDLE:
		if detection_component._check_detect():
			state = State.CHASE
	_hp_bar._update_health_bar(amount)

func _physics_process(delta: float) -> void:
	if state == State.DEAD: return

	if not is_on_floor():
		velocity.y += (GRAVITY * -1) * delta

	match state:
		State.IDLE:		_do_idle(delta)
		State.PATROL:	_do_patrol(delta)
		State.CHASE:	_do_chase(delta)
		State.ATTACK:	_do_attack(delta)
		State.STAND:	_do_stand(delta)

	move_and_slide()

func _do_stand(_delta: float) -> void:
	# Stand Still and Do Nothing
	pass

func _do_idle(delta: float) -> void:
	velocity.x = 0.0; velocity.z = 0.0
	_patrol_wait += delta
	if detection_component._check_detect():
		state = State.CHASE; return
	if _patrol_wait > 2.0:
		state = State.PATROL; return

func _do_patrol(delta: float) -> void:
	if detection_component._check_detect():
		state = State.CHASE; return
	_patrol_wait += delta
	var dist_to_target:float = global_position.distance_to(_patrol_target)
	if dist_to_target < 0.8:
		state = State.IDLE; return
	elif _patrol_wait > 2.0:
		state = State.IDLE; return
	movement_component._move_toward(_patrol_target, move_speed * 0.6, delta)

func _do_chase(delta: float) -> void:
	if not detection_component._check_detect():
		state = State.PATROL; return
	
	if melee_attack_component.is_in_range() or ranged_attack_component.is_in_range():
		velocity.x = 0.0; velocity.z = 0.0
		state = State.ATTACK; return
	movement_component._move_toward(current_target.global_position, move_speed, delta)

func _do_attack(delta: float) -> void:
	if not melee_attack_component.is_in_range() and not ranged_attack_component.is_in_range():
		state = State.CHASE; return

	movement_component._face_target(current_target.global_position, delta * 8.0)

	if melee_attack_component.can_attack():
		_head_icon.texture = melee_icon
		melee_attack_component._do_attack([_muzzle])
	elif(ranged_attack_component.can_attack()):
		ranged_attack_component._do_attack([_muzzle])
		_head_icon.texture = ranged_icon

func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO

	# Flash red then fade
	if _mesh:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.0, 0.0)
		_mesh.set_surface_override_material(0, mat)

	enemy_died.emit(global_position)
	drop_item_component._try_drop_items()
	
	for n in self.get_children():
		self.remove_child(n)
		n.queue_free()
	self.queue_free()

func setTarget() -> void:
	current_target = detection_component.getTargets()[0]
	melee_attack_component.setTarget(current_target)
	ranged_attack_component.setTarget(current_target)

func _set_patrol_target() -> void:
	var offset: Vector3 = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0.0,
		randf_range(-patrol_radius, patrol_radius)
	)
	_patrol_target = _spawn_pos + offset
