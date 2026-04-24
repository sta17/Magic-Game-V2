extends Node
class_name MovementComponent

@export var movementPoint: CharacterBody3D:
	set(value):
		movementPoint = value
		rotationPoint = value
@export var rotationPoint: Node3D

func _move_toward(target: Vector3, speed: float, delta: float) -> void:
	var flat_dir: Vector3 = (target - rotationPoint.global_position)
	flat_dir.y = 0.0
	if flat_dir.length() < 0.01:
		movementPoint.velocity.x = 0.0; movementPoint.velocity.z = 0.0
		return
	flat_dir = flat_dir.normalized()
	movementPoint.velocity.x = flat_dir.x * speed
	movementPoint.velocity.z = flat_dir.z * speed
	_face_target(target, delta * 6.0)

func _face_target(target: Vector3, weight: float) -> void:
	var dir: Vector3 = (target - rotationPoint.global_position)
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var target_angle:float = atan2(dir.x, dir.z)
	rotationPoint.rotation.y = lerp_angle(rotationPoint.rotation.y, target_angle, weight)
