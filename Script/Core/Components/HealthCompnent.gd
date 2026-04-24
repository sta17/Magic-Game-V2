extends Node
class_name HealthComponent

#borrowed from myself and the third person combat prototype

signal took_damage(amount:float)
signal health_increased
signal zero_health

@export var enabled: bool = true
@export_category("Health")
@export var health:		float = 0
@export var health_max:	float = 100

func _ready() -> void:
	if health == 0:
		health = health_max

func incoming_damage(source: DamageSource) -> void:
	if not enabled: return
	var attack_component: AttackComponent = source.attack_component
	take_damage(attack_component.attack_damage)

func take_damage(amount: float) -> void:
	if not enabled:
		return
	
	if not is_alive():
		return
	health = maxf(0.0, health - amount)
	health_increased.emit()
	flash_damage()

	took_damage.emit(amount)

	if health <= 0.0:
		zero_health.emit()

func flash_damage() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0, 0, 0.35)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)

func _max_hp() -> float:
	return health_max #+ equipment.get_health_bonus()

func calculateRegen(bonusRegen: float) -> bool:
	if bonusRegen > 0.0 and health < health_max:
		health = minf(health + bonusRegen, health_max)
		health_increased.emit()
		return true
	return false

func heal(amount: float) -> bool:
	health = minf(health + amount, health_max)
	health_increased.emit()
	return true

func is_alive() -> bool:
	return health > 0
