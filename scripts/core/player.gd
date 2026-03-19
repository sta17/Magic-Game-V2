extends CharacterBody3D
class_name Player

const ConsumableData    = preload("res://scripts/items/consumable_data.gd")
const GrenadeProjectile = preload("res://scripts/gameplay/grenade_projectile.gd")

const _BulletScene  := preload("res://scenes/bullet.tscn")
const _PISTOL_RES   := preload("res://resources/items/pistol.tres")
const _MEDKIT_RES   := preload("res://resources/items/medkit.tres")
const _GRENADE_RES  := preload("res://resources/items/grenade.tres")
const _IMP_RING_RES := preload("res://resources/items/improved_medic_ring.tres")

#region Movement

const WALK_SPEED:   float = 5.0
const SPRINT_SPEED: float = 8.5
const JUMP_FORCE:   float = 5.5
const GRAVITY:      float = -9.8
const MOUSE_SENS:   float = 0.0025

#endregion

#region Stats

@export var max_health: float = 100.0
var health: float

#endregion

#region Camera defaults

var _default_spring_length: float = 3.5
var _default_spring_x:      float = 0.8

#endregion

#region Shooting state

var _shoot_cooldown: float = 0.0
var _reload_timer:   float = 0.0
var _is_reloading:   bool  = false
var _is_aiming:      bool  = false

var _is_dead: bool = false
var _score:   int  = 0
var _kills:   int  = 0

#endregion

#region Systems

var inventory: Inventory
var equipment: EquipmentManager
var ability_list: AbilityList

## Tracks which ability each equipment slot currently grants. Key = slot name string.
var _equipment_abilities: Dictionary = {}

#endregion

#region Scene nodes

@onready var _pivot:     Node3D        = $CameraPivot
@onready var _spring:    SpringArm3D   = $CameraPivot/SpringArm3D
@onready var _cam:       Camera3D      = $CameraPivot/SpringArm3D/Camera3D
@onready var _muzzle:    Marker3D      = $BodyMesh/MuzzlePoint
@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _interact:  Area3D         = $InteractArea
@onready var _hud = $HUD

#endregion

signal health_changed(current: float, maximum: float)
signal player_died

func _ready():
	add_to_group("player")
	health = max_health
	# Capture camera rest position from the scene so the editor values are used
	_default_spring_length = _spring.spring_length
	_default_spring_x      = _spring.position.x
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	inventory = Inventory.new()
	add_child(inventory)

	equipment = EquipmentManager.new()
	add_child(equipment)

	ability_list = AbilityList.new()
	add_child(ability_list)
	ability_list.add_ability(GrenadeAbility.new())
	ability_list.add_ability(HealAbility.new())
	ability_list.add_ability(MeleeAbility.new())
	ability_list.add_ability(EnergyBoltAbility.new())
	ability_list.add_ability(SpeedBootsAbility.new())
	ability_list.add_ability(PowerGloveAbility.new())
	ability_list.add_ability(MedicRingAbility.new())
	equipment.weapon_equipped.connect(_on_weapon_equipped)
	equipment.armor_equipped.connect(_on_armor_equipped)
	equipment.accessory_equipped.connect(_on_accessory_equipped)
	equipment.slot_cleared.connect(_on_slot_cleared)

	_interact.area_entered.connect(_on_interact_area_entered)
	_interact.area_exited.connect(_on_interact_area_exited)

	# Default starter weapon
	var pistol: WeaponData = _PISTOL_RES.duplicate()
	inventory.add_item(pistol)
	equipment.equip_item(pistol)

	# Starter consumables
	var medkit: ConsumableData = _MEDKIT_RES.duplicate()
	medkit.quantity = 2
	inventory.add_item(medkit)

	var grenade: ConsumableData = _GRENADE_RES.duplicate()
	grenade.quantity = 2
	inventory.add_item(grenade)

	var imp_ring: AccessoryData = _IMP_RING_RES.duplicate(true)
	inventory.add_item(imp_ring)

	_update_hud_all()

	# Initialize drag-and-drop inventory UI
	(_hud.inv_panel as InventoryUI).init(self)

	# Initialize hotbar and link it to the inventory UI
	_hud.hotbar_panel.init(self)
	(_hud.inv_panel as InventoryUI).set_hotbar(_hud.hotbar_panel)

	# Equip after UI is ready so the granted ability auto-fills the passive hotbar
	equipment.equip_item(imp_ring)

#region Input

# _input fires before UI so mouse look is never swallowed by HUD Controls.
func _input(event: InputEvent):
	if _is_dead:
		return
	if event is InputEventMouseMotion and \
	   Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pivot.rotate_x(-event.relative.y * MOUSE_SENS)
		_pivot.rotation.x = clampf(_pivot.rotation.x, -PI * 0.38, PI * 0.30)
	# Scroll wheel cycles through hotbar slots (fires before UI so it always works)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_hud.hotbar_panel.scroll(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_hud.hotbar_panel.scroll(1)
			get_viewport().set_input_as_handled()

# Key / button actions remain in _unhandled_input so UI can consume them.
func _unhandled_input(event: InputEvent):
	if _is_dead:
		return

	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_hud.hotbar_panel.use_selected()

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("reload"):
		_start_reload()

	if event.is_action_pressed("escape_mouse"):
		get_tree().quit()

#endregion

#region Physics

func _physics_process(delta: float):
	if _is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_shoot_cooldown -= delta

	if _is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()

	# Health regen from accessory and passive ability slots
	var inv_ui := _hud.inv_panel as InventoryUI
	var regen: float = equipment.get_health_regen() + inv_ui.get_passive_health_regen()
	if regen > 0.0 and health < _max_hp():
		health = minf(health + regen * delta, _max_hp())
		_hud.update_hp(health, _max_hp())

	# Movement
	var spd := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	spd += equipment.get_speed_bonus() + inv_ui.get_passive_speed_bonus()

	var raw := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
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

	# Aiming (zoom spring arm)
	_is_aiming = Input.is_action_pressed("aim")
	var target_len: float = 1.2 if _is_aiming else _default_spring_length
	var target_x:   float = 0.3 if _is_aiming else _default_spring_x
	_spring.spring_length = lerpf(_spring.spring_length, target_len, delta * 12.0)
	_spring.position.x    = lerpf(_spring.position.x,    target_x,   delta * 12.0)

	_hud.set_crosshair_size(6.0 if _is_aiming else 14.0)

	if Input.is_action_pressed("shoot") and not _is_reloading:
		_try_shoot()

	move_and_slide()

#endregion

#region Shooting

func _try_shoot():
	if not equipment.equipped_weapon or _shoot_cooldown > 0.0:
		return
	var w := equipment.equipped_weapon
	if w.ammo_current <= 0:
		_start_reload()
		return
	_shoot_cooldown = w.fire_rate
	for _i in range(w.pellets):
		_fire_bullet(w)
	w.ammo_current -= 1
	_hud.update_ammo(equipment.equipped_weapon)
	if w.ammo_current <= 0:
		_start_reload()

func _fire_bullet(w: WeaponData):
	var bullet: Bullet = _BulletScene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var spread := w.bullet_spread * (1.0 if _is_aiming else 2.0)
	var dir := -_cam.global_transform.basis.z
	dir += Vector3(randf_range(-spread, spread),
				   randf_range(-spread, spread),
				   randf_range(-spread, spread))
	dir = dir.normalized()

	bullet.global_position = _muzzle.global_position
	bullet.direction = dir
	bullet.speed     = w.bullet_speed
	bullet.damage    = w.damage + equipment.get_damage_bonus() \
		+ (_hud.inv_panel as InventoryUI).get_passive_damage_bonus()
	bullet.shooter   = self

func _start_reload():
	if _is_reloading:
		return
	if not equipment.equipped_weapon:
		return
	var w := equipment.equipped_weapon
	if w.ammo_current >= w.ammo_max:
		return
	_is_reloading = true
	_reload_timer = w.reload_time
	_hud.show_reload(true)

func _finish_reload():
	_is_reloading = false
	if equipment.equipped_weapon:
		equipment.equipped_weapon.ammo_current = equipment.equipped_weapon.ammo_max
	_hud.update_ammo(equipment.equipped_weapon)
	_hud.show_reload(false)

#endregion

#region Interaction

var _nearby_pickups: Array = []

func _on_interact_area_entered(area: Area3D) -> void:
	if area is Pickup:
		_nearby_pickups.append(area)
		area.show_label(true)

func _on_interact_area_exited(area: Area3D) -> void:
	if area is Pickup:
		area.show_label(false)
	_nearby_pickups.erase(area)

func _try_interact():
	for pickup in _nearby_pickups:
		if is_instance_valid(pickup):
			if (pickup as Pickup).try_pickup(self):
				return

func pickup_item(item: ItemData) -> bool:
	if inventory.is_full():
		_hud.show_notif("Inventory full!", Color.RED)
		return false
	if not inventory.add_item(item):
		return false
	_hud.show_notif("Picked up: " + item.item_name, item.get_type_color())

	# Auto-equip empty slots
	match item.item_type:
		ItemData.ItemType.WEAPON:
			if not equipment.equipped_weapon:
				equipment.equip_item(item)
		ItemData.ItemType.ARMOR:
			if not equipment.equipped_armor:
				equipment.equip_item(item)
		ItemData.ItemType.ACCESSORY:
			if not equipment.equipped_accessory:
				equipment.equip_item(item)
	return true

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
	return max_health + equipment.get_health_bonus()

func _die():
	_is_dead = true
	player_died.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_hud.show_death()

func add_score(points: int):
	_score += points
	_hud.update_score(_score)

func add_kill():
	_kills += 1
	_hud.update_kills(_kills)

#endregion

#region Equipment callbacks

func _on_weapon_equipped(w: WeaponData):
	_update_granted_ability("weapon", w)
	_update_hud_all()

func _on_armor_equipped(a: ArmorData):
	_update_granted_ability("armor", a)
	_update_hud_all()

func _on_accessory_equipped(ac: AccessoryData):
	_update_granted_ability("accessory", ac)
	_update_hud_all()

func _on_slot_cleared(slot: String):
	_remove_granted_ability(slot)
	_update_hud_all()

func _update_granted_ability(slot: String, item: ItemData) -> void:
	_remove_granted_ability(slot)
	if item and item.granted_ability:
		var ab: AbilityData = item.granted_ability.duplicate()
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
	_hud.update_ammo(equipment.equipped_weapon)
	_hud.update_equip(equipment.equipped_armor, equipment.equipped_accessory)

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

func use_item(item: ItemData) -> void:
	if not item is ConsumableData:
		return
	var c := item as ConsumableData
	match c.consumable_type:
		ConsumableData.ConsumableType.MEDICINE:
			heal((c as MedicineData).heal_amount)
		ConsumableData.ConsumableType.GRENADE:
			var g := c as GrenadeData
			throw_grenade_ability(g.damage, g.explosion_radius, g.throw_speed)
	# Decrement stack; only remove when stack is empty
	if item.stackable and item.quantity > 1:
		item.quantity -= 1
		inventory.inventory_changed.emit()
	else:
		inventory.remove_item(item)

## Heals the player by amount, capped at max HP. Called by HealAbility and use_item.
func heal(amount: float) -> void:
	health = minf(health + amount, _max_hp())
	_hud.update_hp(health, _max_hp())
	_hud.show_notif("+%d HP restored" % int(amount), Color(0.3, 1.0, 0.4))

## Throws a grenade with the given stats. Called by GrenadeAbility and use_item.
func throw_grenade_ability(p_damage: float, p_radius: float, p_throw_speed: float) -> void:
	var inv: Control = _hud.inv_panel
	if inv.visible:
		inv.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var grenade := GrenadeProjectile.new()
	grenade.damage = p_damage
	grenade.radius = p_radius
	get_tree().current_scene.add_child(grenade)
	grenade.global_position = _cam.global_position + (-_cam.global_transform.basis.z * 0.8)
	var dir := -_cam.global_transform.basis.z + Vector3(0, 0.18, 0)
	grenade.linear_velocity = dir.normalized() * p_throw_speed
	_hud.show_notif("Grenade thrown!", Color(1.0, 0.7, 0.2))

#endregion
