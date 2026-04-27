extends Area3D
class_name HitboxComponent

signal damage_source_hit(source: DamageSource)

@export var parent: Node3D
@export var _damage_sources_in_hitbox: Array[DamageSource] = []
@export var radius: float = 0.5:
	set(value):
		radius = value
		collision.shape.radius = value
@export var height: float = 2.0:
	set(value):
		height = value
		collision.shape.height = value
@export var detection_enabled: bool = true:
	set(value):
		var b: bool = value
		monitoring = b
@export var collision: CollisionShape3D

# DamageSource as key, damage_source.instance as value
var _successful_hits: Dictionary

func _process(_delta: float) -> void:
	if not detection_enabled: return
	if len(_damage_sources_in_hitbox) == 0: return
	
	for damage_source in _damage_sources_in_hitbox:
		if damage_source.entity == parent:
			continue
		if not damage_source.can_damage:
			continue
		
		# this damage_source has already successfully gotten a hit in
		# and so this subsequent detection should be ignored.
		if _successful_hits.has(damage_source) and \
		damage_source.instance == _successful_hits[damage_source]:
			continue
		
		_successful_hits[damage_source] = damage_source.instance
		
		damage_source_hit.emit(damage_source)
		_damage_sources_in_hitbox.erase(damage_source)
		if damage_source.hit_considered():
			_successful_hits.erase(damage_source)

func is_target_valid(object: Node3D) -> bool:
	if object in _damage_sources_in_hitbox: return false
	if object == parent: return false
	if object == self: return false
	if object is DetectionComponent: return false
	if object is HitboxComponent: return false
	if object is DamageSource: 
		if (object as DamageSource).entity == parent:
			return false
		elif (object as DamageSource).entity == NPC:
			return false
		else: 
			return true
	if object == NPC: return false
	if not object is Enemy or not object is EnemyStaticRotating or not object is Player: return false
	return true

func _on_area_entered(area: Area3D) -> void:
	if is_target_valid(area):
		_damage_sources_in_hitbox.append(area)

func _on_area_exited(area: Area3D) -> void:
	if area in _damage_sources_in_hitbox:
		_damage_sources_in_hitbox.erase(area)
		_successful_hits.erase(area)

func _on_body_entered(body: Node3D) -> void:
	if is_target_valid(body):
		_damage_sources_in_hitbox.append(body)

func _on_body_exited(body: Node3D) -> void:
	if body in _damage_sources_in_hitbox:
		_damage_sources_in_hitbox.erase(body)
		_successful_hits.erase(body)
