@icon("res://Assets/Icons/Pixel-Boy/color/icon_life_bar.png")
extends Label3D
class_name Spawn_Text_Label

func _spawn_damage_number(amount: float) -> void:
	self.text = "-%d" % int(amount)
	self.global_position = global_position + Vector3(0, 2.4, 0)
	get_tree().current_scene.add_child(self)
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", self.global_position + Vector3(0, 1.2, 0), 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(self.queue_free).set_delay(0.8)
