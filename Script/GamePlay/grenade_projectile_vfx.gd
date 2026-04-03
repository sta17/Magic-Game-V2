@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_projectile.png")
extends MeshInstance3D
class_name GrenadeProjectileVFX

@export var radius: float = 5.0

func _startVFX() -> void:
	var mat: StandardMaterial3D = self.get_active_material(0)
	var target_scale := Vector3.ONE * radius * 2.0
	var tween := self.create_tween()
	tween.tween_property(self, "scale", target_scale, 0.35)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.tween_callback(self.queue_free)
