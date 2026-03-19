extends CharacterBody3D
class_name Player

const _BulletScene  := preload("res://Scenes/bullet.tscn")

#region Movement
@export var WALK_SPEED:   float = 10
@export var SPRINT_SPEED: float = 15
@export var JUMP_FORCE:   float = 5.5
@export var GRAVITY:      float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var MOUSE_SENS:   float = 0.0025
#endregion

#region Player Stats
@export var health:float = 0
@export var health_max:float = 100
var _is_dead: bool = false
var _allow_movement:bool = true
var _ui_mode:bool = false

var _shoot_cooldown: float = 0.0
@export var cooldown_sec: float = 0.7
#endregion

#region Scene nodes
@onready var _pivot:     Node3D        = $CameraPivot
@onready var _cam:       Camera3D      = $CameraPivot/SpringArm3D/Camera3D
@onready var _muzzle:    Marker3D      = $MeshInstance3D/MeshInstance3D/Marker3D
@onready var _hud = $HUD
#endregion

#region Systems
var inventory: Inventory
var equipment: EquipmentManager
var ability_list: AbilityList
var _equipment_abilities: Dictionary = {}
var inv_ui: InventoryUI
#endregion

#region Other
const INTERACT_RANGE: float = 2.2
var _nearby_pickups: Array = []
signal health_changed(current: float, maximum: float)
signal player_died
#endregion

func _ready():
	add_to_group("player")
	if health == 0:
		health = health_max
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	inventory = Inventory.new()
	add_child(inventory)

	equipment = EquipmentManager.new()
	add_child(equipment)
	
	ability_list = AbilityList.new()
	add_child(ability_list)
	
	equipment.weapon_equipped.connect(_on_weapon_equipped)
	equipment.armor_equipped.connect(_on_armor_equipped)
	equipment.accessory_equipped.connect(_on_accessory_equipped)
	equipment.slot_cleared.connect(_on_slot_cleared)
	
	_update_hud_all()
	
	(_hud.inv_panel as InventoryUI).init(self)
	inv_ui = _hud.inv_panel
	_hud.hotbar_panel.init(self)
	(_hud.inv_panel as InventoryUI).set_hotbar(_hud.hotbar_panel)

#region Input

func _input(event: InputEvent):
	if _is_dead:
		return
	
	if event is InputEventMouseMotion and \
	   Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pivot.rotate_x(-event.relative.y * MOUSE_SENS)
		_pivot.rotation.x = clampf(_pivot.rotation.x, -PI * 0.38, PI * 0.30)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_hud.hotbar_panel.scroll(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_hud.hotbar_panel.scroll(1)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent):
	if _is_dead:
		return

	if event.is_action_pressed("toggle_inventory"):
		_ui_mode = true
		_toggle_inventory()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_hud.hotbar_panel.use_selected()

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("toggle_main_menu"):
		_ui_mode = true
		get_tree().quit()

#endregion

#region Physics
func _physics_process(delta: float):
	if _is_dead:
		return
	
	if not is_on_floor():
		velocity.y += (GRAVITY * -1) * delta

	_shoot_cooldown -= delta

	# Health regen from accessory and passive ability slots
	var regen: float = equipment.get_health_regen() + inv_ui.get_passive_health_regen()
	if regen > 0.0 and health < _max_hp():
		health = minf(health + regen * delta, _max_hp())
		_hud.update_hp(health, _max_hp())

	if _allow_movement:
		var spd := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		spd += equipment.get_speed_bonus() + inv_ui.get_passive_speed_bonus()
		
		var raw := Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
		)
		var dir := (transform.basis * Vector3(raw.x, 0.0, raw.y)).normalized()
		if dir.length() > 0.01:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		else:
			velocity.x = move_toward(velocity.x, 0.0, spd * 0.3)
			velocity.z = move_toward(velocity.z, 0.0, spd * 0.3)
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_FORCE
		
		if Input.is_action_pressed("attack") and !_ui_mode:
			_try_attack()
		
		move_and_slide()
		
#endregion

#region Interaction

func _on_interact_area_area_entered(area: Area3D) -> void:
	if area is PickUpItem:
		if (area as PickUpItem).autoCollect:
			(area as PickUpItem).Collect(self)
		else:
			_nearby_pickups.append(area)

func _on_interact_area_area_exited(area: Area3D) -> void:
	if area is PickUpItem:
		_nearby_pickups.erase(area)

func _try_interact():
	for pickup in _nearby_pickups:
		if is_instance_valid(pickup):
			if pickup is PickUpItem:
				(pickup as PickUpItem).Collect(self)
				return
			

func pickup_item_quantiy(quantityCounter : QuantitySlot) -> bool:
	if inventory.is_full():
		_hud.show_notif("Inventory full!", Color.RED)
		return false
	if not inventory.add_item_with_quantity(quantityCounter):
		return false
	_hud.show_notif("Picked up: " + quantityCounter.item.item_name, quantityCounter.get_type_color())

	# Auto-equip empty slots
	match quantityCounter.item.item_type:
		ItemData.ItemType.WEAPON:
			if not equipment.equipped_weapon:
				equipment.equip_item(quantityCounter)
		ItemData.ItemType.ARMOR:
			if not equipment.equipped_armor:
				equipment.equip_item(quantityCounter)
		ItemData.ItemType.ACCESSORY:
			if not equipment.equipped_accessory:
				equipment.equip_item(quantityCounter)
	return true
	
#endregion

#region Attack

func _try_attack():
	if not equipment.equipped_weapon or _shoot_cooldown > 0.0:
		return
	var w: WeaponData = equipment.equipped_weapon
	if w.get_weapon_type_name() == "Melee":
		try_melee(w)
	if w.get_weapon_type_name() == "Ranged":
		try_ranged(w)

func try_ranged(equipped_weapon: WeaponData):
	_shoot_cooldown = equipped_weapon.fire_rate
	for _i in range(equipped_weapon.pellets):
		var bullet: Bullet = _BulletScene.instantiate()
		get_tree().current_scene.add_child(bullet)

		var spread := equipped_weapon.bullet_spread *  2.0
		var dir := -_cam.global_transform.basis.z
		dir += Vector3(randf_range(-spread, spread),
					   randf_range(-spread, spread),
					   randf_range(-spread, spread))
		dir = dir.normalized()

		bullet.global_position = _muzzle.global_position
		bullet.direction = dir
		bullet.speed     = equipped_weapon.bullet_speed
		bullet.damage    = equipped_weapon.damage + equipment.get_damage_bonus() \
			+ (_hud.inv_panel as InventoryUI).get_passive_damage_bonus()
		bullet.shooter   = self

func try_melee(equipped_weapon: WeaponData):
	_shoot_cooldown = equipped_weapon.fire_rate

	var forward: Vector3 = -global_transform.basis.z
	var hit_any := false

	for enemy in self.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		# Must be within range and roughly in front (within ~73°)
		if to_enemy.length() <= equipped_weapon.weapon_range and to_enemy.normalized().dot(forward) > 0.3:
			if enemy.has_method("take_damage"):
				enemy.take_damage(equipped_weapon.damage)
				hit_any = true

	if hit_any:
		_hud.show_notif("Melee hit! -%d" % int(equipped_weapon.damage), Color(1.0, 0.45, 0.1))
	else:
		_hud.show_notif("No enemies in range.", Color(0.55, 0.55, 0.55))

#endregion

#region Combat

func take_damage(amount: float):
	if _is_dead:
		return
	var reduced := maxf(0.0, amount - equipment.get_defense())
	health = maxf(0.0, health - reduced)
	health_changed.emit(health, _max_hp())
	_hud.update_hp(health, _max_hp())
	_hud.flash_damage()

	if health <= 0.0:
		_die()

func _max_hp() -> float:
	return health_max #+ equipment.get_health_bonus()

func _die():
	_is_dead = true
	player_died.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_hud.show_death()

#endregion

#region Equipment callbacks

func _on_weapon_equipped(w: QuantitySlot):
	_update_granted_ability("weapon", w)
	_update_hud_all()

func _on_armor_equipped(a: QuantitySlot):
	_update_granted_ability("armor", a)
	_update_hud_all()

func _on_accessory_equipped(ac: QuantitySlot):
	_update_granted_ability("accessory", ac)
	_update_hud_all()

func _on_slot_cleared(slot: String):
	_remove_granted_ability(slot)
	_update_hud_all()
	
func _update_granted_ability(slot: String, item: QuantitySlot) -> void:
	_remove_granted_ability(slot)
	if item and item.item.granted_ability:
		var ab: AbilityData = item.item.granted_ability.duplicate()
		ability_list.add_ability(ab)
		_equipment_abilities[slot] = ab
		if ab.is_passive:
			(_hud.inv_panel as InventoryUI).auto_add_passive(ab)

func _remove_granted_ability(slot: String) -> void:
	if _equipment_abilities.has(slot):
		var ab: AbilityData = _equipment_abilities[slot]
		ability_list.remove_ability(ab)
		if ab.is_passive:
			(_hud.inv_panel as InventoryUI).auto_remove_passive(ab)
		_equipment_abilities.erase(slot)

#endregion

#region HUD helpers

func _update_hud_all():
	_hud.update_hp(health, _max_hp())

#endregion

#region Inventory

func _toggle_inventory():
	var inv: Control = _hud.inv_panel
	inv.visible = not inv.visible
	if inv.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#endregion

#region Consumable use

func use_item(item: QuantitySlot) -> void:
	if not item.item is ConsumableData:
		return
	#var c := item as ConsumableData
	#match c.consumable_type:
	#	ConsumableData.ConsumableType.MEDICINE:
	#		heal((c as MedicineData).heal_amount)
	item.item.granted_ability.execute(self)
	# Decrement stack; only remove when stack is empty
	if item.item.stackable and item.quantity > 1:
		item.quantity -= 1
		inventory.inventory_changed.emit()
	else:
		inventory.remove_item_quantity(item)

func heal(amount: float) -> void:
	health = minf(health + amount, _max_hp())
	_hud.update_hp(health, _max_hp())
	_hud.show_notif("+%d HP restored" % int(amount), Color(0.3, 1.0, 0.4))
	
#endregion
