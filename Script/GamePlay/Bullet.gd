@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_bullet.png")
extends Area3D
class_name Bullet

var direction: Vector3 = Vector3.FORWARD
var speed:     float   = 60.0
var damage:    float   = 15.0
var shooter:   Node3D  = null
var lifetime:  float   = 3.0

var _elapsed: float = 0.0
var _done:    bool  = false

func _ready() -> void:
	# Disable Area3D monitoring — we use a raycast each physics tick instead,
	# which prevents tunneling on fast bullets.
	monitoring = false

func _physics_process(delta: float) -> void:
	if _done:
		return

	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return

	var motion := direction * speed * delta

	# Cast a ray along the full distance we're about to travel this tick.
	var space  := get_world_3d().direct_space_state
	var query  := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + motion,
		collision_mask
	)
	# Exclude the shooter so the bullet never hits its own owner.
	if shooter and shooter.get_rid().is_valid():
		query.exclude = [shooter.get_rid()]

	var hit := space.intersect_ray(query)
	if hit:
		_done = true
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(damage)
		global_position = hit.position
		_spawn_impact()
		queue_free()
		return

	global_position += motion

func _spawn_impact() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.omni_range  = 2.0
	light.light_energy = 4.0
	get_tree().current_scene.add_child(light)
	light.global_position = global_position
	var tween := get_tree().create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.15)
	tween.tween_callback(light.queue_free)
