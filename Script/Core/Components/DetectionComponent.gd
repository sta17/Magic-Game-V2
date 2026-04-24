extends Area3D
class_name DetectionComponent

@export var parent: Node3D
@export var targets: Array[Node3D] = []
@export var detection_range: float = 16.0:
	set(value):
		detection_range = value
		collision.shape.radius = value/2
@export var detection_enabled: bool = true:
	set(value):
		var b: bool = value
		monitoring = b
@export var collision: CollisionShape3D

func getTargets() -> Array[Node3D]:
	return targets

func _check_detect() -> bool:
	if targets.size() > 0:
		return true
	return false

func is_target_valid(object: Node3D) -> bool:
	if object in targets: return false
	if object == parent: return false
	if object == self: return false
	if object is DetectionComponent:
		if (object as DetectionComponent).parent == parent:
			return false
		elif (object as DetectionComponent).parent == NPC:
			return false
	if object is HitboxComponent:
		if (object as HitboxComponent).parent == parent:
			return false
		elif (object as HitboxComponent).parent == NPC:
			return false
	if object == DamageSource: return false
	if object == NPC: return false
	return true
	

func _on_area_entered(area: Area3D) -> void:
	if is_target_valid(area):
		if area is DetectionComponent:
			targets.append((area as DetectionComponent).parent)
		elif area is HitboxComponent:
			targets.append((area as HitboxComponent).parent)

func _on_area_exited(area: Area3D) -> void:
	if area in targets:
		targets.erase(area)

func _on_body_entered(body: Node3D) -> void:
	if is_target_valid(body):
		if body is DetectionComponent:
			targets.append((body as DetectionComponent).parent)
		elif body is HitboxComponent:
			targets.append((body as HitboxComponent).parent)

func _on_body_exited(body: Node3D) -> void:
	if body in targets:
		targets.erase(body)
