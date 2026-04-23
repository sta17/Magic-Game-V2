extends Area3D
class_name DetectionComponent

@export var targets: Array[Node3D] = []
@export var detection_range: float = 16.0:
	set(value):
		detection_range = value
		collision.shape.Radius = value/2
@export var detection_enabled: bool = true:
	set(value):
		var b: bool = value
		monitoring = b

var collision: CollisionObject3D

func getTargets() -> Array[Node3D]:
	return targets

func _check_detect() -> bool:
	if targets.size() > 0:
		return true
	return false

func _on_area_entered(area: Area3D) -> void:
	if area not in targets:
		targets.append(area)

func _on_area_exited(area: Area3D) -> void:
	if area in targets:
		targets.erase(area)

func _on_body_entered(body: Node3D) -> void:
	if body not in targets:
		if body is Enemy or EnemyStaticRotating or Player:
			targets.append(body)

func _on_body_exited(body: Node3D) -> void:
	if body in targets:
		targets.erase(body)
