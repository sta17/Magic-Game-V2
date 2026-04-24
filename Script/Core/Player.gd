@icon("res://Assets/Icons/Pixel-Boy/node_3D/icon_character.png")
extends CharacterBody3D
class_name Player

const _BulletScene  := preload("res://Scenes/Bullets and Effects/bullet.tscn")
enum PlayerState { ACTIVE, UI, DIALOG, UIMINIMAL }
enum MovingState { GROUNDED, FLOATING }
enum ActionState { IDLE, MELEE, RANGED }

@export_category("Components")
@export var health_component: HealthComponent
@export var melee_attack_component: MeleeAttackComponent
@export var ranged_attack_component: RangedAttackComponent
@export var hitbox_component: HitboxComponent

#region Movement
@export_category("Movement")
@export var WALK_SPEED:		float = 10
@export var SPRINT_SPEED:	float = 15
@export var JUMP_FORCE:		float = 6
@export var GRAVITY:		float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var MOUSE_SENS:		float = 0.0025
@export var PLAYER_STATE: PlayerState = PlayerState.ACTIVE
@export var MOVING_STATE: MovingState = MovingState.GROUNDED
@export var ACTION_STATE: ActionState = ActionState.IDLE
#endregion

#region Player Stats
var _is_dead: 			bool  = false
var special_key_pressed:bool  = false

var _shoot_cooldown:	float = 0.0
@export var cooldown_sec: float = 0.7
#endregion

#region Scene nodes
@onready var _pivot:	Node3D		= $CameraPivot
@onready var _muzzle:	Marker3D	= $"Kachujin G Rosales/Marker3D"
@onready var _hud:		HUD 		= $HUD
@onready var _model:	ModelData 	= $"Kachujin G Rosales"
#endregion

#region Systems
@export var inventory: Inventory
@export var equipment: EquipmentManager
@export var ability_list: AbilityList
@export var passive_ability_list: AbilityList
@export var _equipment_abilities: Dictionary = {}
#endregion

#region Other
const INTERACT_RANGE: float = 2.2
var _nearby_pickups: Array[PickUpItem] = []
signal player_died
var interactble_entity: Object
var AnimPlayer: AnimationPlayer
var AnimTree: AnimationTree
#endregion

func _ready() -> void:
	add_to_group("player")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	passive_ability_list = AbilityList.new()
	ability_list = AbilityList.new()
	equipment = EquipmentManager.new()
	inventory = Inventory.new()
	inventory.init(self)
	
	equipment.weapon_equipped.connect(_on_weapon_equipped)
	equipment.armor_equipped.connect(_on_armor_equipped)
	equipment.accessory_equipped.connect(_on_accessory_equipped)
	equipment.slot_cleared.connect(_on_slot_cleared)
	
	_hud.init(self)
	
	health_component.took_damage.connect(_hud.update_hp)
	health_component.health_increased.connect(_hud.update_hp)
	health_component.zero_health.connect(_die)
	
	hitbox_component.detection_enabled = true
	hitbox_component.damage_source_hit.connect(health_component.incoming_damage)
	
	melee_attack_component.attacker = self
	ranged_attack_component.attacker = self
	
	_update_hud_all()
	
	AnimPlayer = _model.AnimPlayer
	AnimTree = _model.AnimTree

#region Input

func _input(event: InputEvent) -> void:
	if _is_dead:
		return
	
	if event is InputEventMouseMotion and \
	   Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if PLAYER_STATE == PlayerState.ACTIVE:
			CameraRotate(event)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if PLAYER_STATE == PlayerState.DIALOG:
				_hud.dialogScroll(-1)
			else:
				_hud.hotbarScroll(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if PLAYER_STATE == PlayerState.DIALOG:
				_hud.dialogScroll(1)
			else:
				_hud.hotbarScroll(1)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return

	if event.is_action_pressed("toggle_inventory"):
		if PLAYER_STATE == PlayerState.ACTIVE:
			PLAYER_STATE = PlayerState.UI
			_hud.Show_Inventory()
		elif PLAYER_STATE == PlayerState.UIMINIMAL:
			_hud.ShowHide_Inventory_BoxMinimal(interactble_entity)
			PLAYER_STATE = PlayerState.UI
		else:
			PLAYER_STATE = PlayerState.ACTIVE
			_hud.Hide_Inventory()
			_hud.Hide_Text_Vendor()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_hud.hotbarUseSelected()

	if event.is_action_pressed("special Action"):
		special_key_pressed = true
	elif event.is_action_released("special Action"):
		special_key_pressed = false
		
	if event.is_action_pressed("interact"):
		if PLAYER_STATE == PlayerState.ACTIVE:
			_try_interact()
		elif PLAYER_STATE == PlayerState.DIALOG:
			if !_hud.dialogPromptLine():
				#_try_interact()
				pass
		elif PLAYER_STATE == PlayerState.UIMINIMAL:
			_try_interact()
	if event.is_action_pressed("next_page"):
		if PLAYER_STATE == PlayerState.DIALOG:
			_hud.dialogPromptLine()
	if event.is_action_pressed("previous_page"):
		if PLAYER_STATE == PlayerState.DIALOG:
			_hud.dialogWindow.promptPreviousLine()
	if event.is_action_pressed("attack"):
		if PLAYER_STATE == PlayerState.DIALOG:
			_hud.dialogWindow.sendSelection()
	if event.is_action_pressed("negative_interact"):
		if PLAYER_STATE == PlayerState.DIALOG: 
			ExitDialogeUI()
		elif  PLAYER_STATE == PlayerState.ACTIVE: 
			get_tree().quit()
		elif  PLAYER_STATE == PlayerState.UI: 
			get_tree().quit()
	elif event.is_action_pressed("toggle_main_menu"):
		PLAYER_STATE = PlayerState.ACTIVE
		get_tree().quit()

#endregion

#region Physics
func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	
	if ACTION_STATE == ActionState.IDLE:
		pass
	elif ACTION_STATE == ActionState.RANGED:
		ACTION_STATE = ActionState.IDLE
		pass
	elif ACTION_STATE == ActionState.MELEE:
		AnimTree.set("parameters/conditions/Attack End",true)
		AnimTree.set("parameters/conditions/Attack Start",false)
		AnimTree.set("parameters/conditions/Attack",false)
		ACTION_STATE = ActionState.IDLE
	
	# Health regen from accessory and passive ability slots
	var regen: float = equipment.get_health_regen() + passive_ability_list.get_passive_health_regen()
	regen = regen * delta
	health_component.calculateRegen(regen)
	
	if PLAYER_STATE == PlayerState.ACTIVE:
		_shoot_cooldown -= delta
		
		if MOVING_STATE == MovingState.GROUNDED:
			
			var spd := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
			spd += equipment.get_speed_bonus() + passive_ability_list.get_passive_speed_bonus()
		
			var inputDir: Vector2 = Input.get_vector("move_right","move_left","move_back","move_forward")
		
			var dir: Vector3 = (transform.basis * Vector3(inputDir.x, 0.0, inputDir.y)).normalized()
		
			if inputDir == Vector2.ZERO:
				AnimTree.set("parameters/conditions/is Moving",false)
				AnimTree.set("parameters/Moving Tree/Moving/blend_position",Vector2.ZERO)
				AnimTree.set("parameters/Moving Tree/Moving Armed/blend_position",Vector2.ZERO)
				AnimTree.set("parameters/conditions/is idle",true)
			else:
				AnimTree.set("parameters/conditions/is Moving",true)
				AnimTree.set("parameters/Moving Tree/Moving/blend_position",inputDir.normalized())
				AnimTree.set("parameters/Moving Tree/Moving Armed/blend_position",inputDir.normalized())
				AnimTree.set("parameters/conditions/is idle",false)
		
			if dir.length() > 0.01:
				velocity.x = dir.x * spd
				velocity.z = dir.z * spd
			else:
				velocity.x = move_toward(velocity.x, 0.0, spd * 0.3)
				velocity.z = move_toward(velocity.z, 0.0, spd * 0.3)
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			MOVING_STATE = MovingState.FLOATING
			velocity.y = JUMP_FORCE
			AnimTree.set("parameters/conditions/Landing",false)
			AnimTree.set("parameters/conditions/Jump",true)
			AnimTree.set("parameters/conditions/is Moving",false)
			AnimTree.set("parameters/conditions/is idle",false)
		elif not is_on_floor():
			velocity.y += (GRAVITY * -1) * delta
			AnimTree.set("parameters/conditions/Jump",false)
		elif is_on_floor():
			MOVING_STATE = MovingState.GROUNDED
			AnimTree.set("parameters/conditions/Landing",true)
			AnimTree.set("parameters/conditions/Jump",false)
		
		if Input.is_action_pressed("attack"):
			_try_attack()
		
		move_and_slide()

func CameraRotate(event: InputEvent) -> void:
	if !special_key_pressed:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pivot.rotation.y = 0
		_pivot.rotate_x(event.relative.y * MOUSE_SENS)
	else:
		_pivot.rotate_y(event.relative.x * MOUSE_SENS)
	
	_pivot.rotation.x = clampf(_pivot.rotation.x, -PI * 0.38, PI * 0.30)

#endregion

#region Interaction

func _on_interact_area_area_entered(area: Area3D) -> void:
	if area is PickUpItem:
		if (area as PickUpItem).autoCollect:
			(area as PickUpItem).Collect(self)
		else:
			_nearby_pickups.append(area)
			area.show_label(true)

func _on_interact_area_area_exited(area: Area3D) -> void:
	if area is PickUpItem:
		_nearby_pickups.erase(area)
		area.show_label(false)

func _on_interact_area_body_entered(body: Node3D) -> void:
	if body is NPC:
		interactble_entity = body
	if body is Box:
		interactble_entity = body

func _on_interact_area_body_exited(body: Node3D) -> void:
	if interactble_entity == body:
		interactble_entity = null

func _try_interact() -> void:
	if !_nearby_pickups.is_empty():
		for pickup: PickUpItem in _nearby_pickups:
			if is_instance_valid(pickup):
				(pickup as PickUpItem).Collect(self)
				return
	if interactble_entity:
		if interactble_entity is NPC:
			if PLAYER_STATE == PlayerState.ACTIVE:
				if (interactble_entity as NPC).interact_script != null:
					PLAYER_STATE = PlayerState.DIALOG
					(interactble_entity as NPC).interact(self)
			elif PLAYER_STATE == PlayerState.DIALOG:
				if (interactble_entity as NPC).interact_script != null:
					PLAYER_STATE = PlayerState.ACTIVE
					(interactble_entity as NPC).interact(self)
		elif  interactble_entity is Box:
			if PLAYER_STATE == PlayerState.ACTIVE:
				PLAYER_STATE = PlayerState.UIMINIMAL
				_hud.ShowHide_Inventory_BoxMinimal(interactble_entity)
			elif _hud.isLootWindowVisible():
				_hud.ShowHide_Inventory_BoxMinimal(interactble_entity)
				PLAYER_STATE = PlayerState.ACTIVE
			elif _hud.isInv_PanelVisible():
				pass
			# Pass the interactble_entity for access of its inventory.
			#_hud.ShowHide_Inventory_Box(interactble_entity)
			#_hud.ShowHide_Inventory_BoxMinimal(interactble_entity)

func pickup_item_quantiy(quantityCounter : QuantitySlot, autoUse : bool) -> bool:
	if inventory.is_full():
		_hud.show_notif("Inventory full!", Color.RED)
		return false
	if !quantityCounter:
		return false
	if autoUse:
		inventory.use_item(quantityCounter)
		return true

	# Auto-equip empty slots
	match quantityCounter.item.item_type:
		ItemData.ItemType.WEAPON:
			if not equipment.equipped_weapon:
				equipment.handle_equip(quantityCounter)
				_hud.show_notif("Picked up: " + quantityCounter.getName(), quantityCounter.get_type_color())
				return true
		ItemData.ItemType.ARMOR:
			if not equipment.equipped_armor:
				equipment.handle_equip(quantityCounter)
				_hud.show_notif("Picked up: " + quantityCounter.getName(), quantityCounter.get_type_color())
				return true
		ItemData.ItemType.ACCESSORY:
			if not equipment.equipped_accessory:
				equipment.handle_equip(quantityCounter)
				_hud.show_notif("Picked up: " + quantityCounter.getName(), quantityCounter.get_type_color())
				return true
	if inventory.add_item(quantityCounter):
		_hud.show_notif("Picked up: " + quantityCounter.getName(), quantityCounter.get_type_color())
		return true
	
	return false

#endregion

#region Attack

func _try_attack() -> void:
	if not equipment.equipped_weapon or _shoot_cooldown > 0.0:
		return
	var w: WeaponData = equipment.equipped_weapon
	if w.get_weapon_type_name() == "Melee":
		try_melee(w)
	elif w.get_weapon_type_name() == "Ranged":
		try_ranged(w)

func try_ranged(equipped_weapon: WeaponData) -> void:
	ACTION_STATE = ActionState.RANGED
	_shoot_cooldown = equipped_weapon.fire_rate
	for _i in range(equipped_weapon.pellets):
		var bullet: Bullet = _BulletScene.instantiate()
		get_tree().current_scene.add_child(bullet)

		var spread := equipped_weapon.bullet_spread *  2.0
		#var dir := -_cam.global_transform.basis.z
		var dir := -_muzzle.global_transform.basis.z
		#dir += Vector3(randf_range(-spread, spread),
		#			   randf_range(-spread, spread),
		#			   randf_range(-spread, spread))
		dir = dir.normalized()

		#bullet.global_position = _muzzle.global_position
		bullet.position = _muzzle.global_position
		bullet.transform.basis = _muzzle.global_transform.basis
		bullet.direction = dir
		bullet.speed     = equipped_weapon.bullet_speed
		bullet.damage    = equipped_weapon.damage + equipment.get_damage_bonus() \
			+ passive_ability_list.get_passive_damage_bonus()
		bullet.shooter   = self

func try_melee(equipped_weapon: WeaponData) -> void:
	ACTION_STATE = ActionState.MELEE
	AnimTree.set("parameters/Moving Tree/Attack Mixing/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	AnimTree.set("parameters/conditions/Attack End",false)
	AnimTree.set("parameters/conditions/Attack Start",true)
	AnimTree.set("parameters/conditions/Attack",true)
	
	_shoot_cooldown = equipped_weapon.fire_rate

	var forward: Vector3 = global_transform.basis.z
	var hit_any := false

	for enemy in self.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		# Must be within range and roughly in front (within ~73°)
		if to_enemy.length() <= equipped_weapon.weapon_range and to_enemy.normalized().dot(forward) > 0.3:
			var damage: float = equipped_weapon.damage \
					+ equipment.get_damage_bonus() \
					+ passive_ability_list.get_passive_damage_bonus()
			if enemy is Enemy:
				#(enemy as Enemy).health_component.take_damage(damage)
				hit_any = true
			elif enemy is EnemyStaticRotating:
				(enemy as EnemyStaticRotating).health_component.take_damage(damage)
				hit_any = true
			elif enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hit_any = true

	if hit_any:
		_hud.show_notif("Melee hit! -%d" % int(equipped_weapon.damage), Color(1.0, 0.45, 0.1))
	else:
		_hud.show_notif("No enemies in range.", Color(0.55, 0.55, 0.55))

#endregion

#region Combat

func take_damage(amount: float) -> void:
	if _is_dead:
		return
	var reduced := maxf(0.0, amount - equipment.get_defense())
	health_component.take_damage(reduced)

func _die() -> void:
	_is_dead = true
	player_died.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_hud.show_death()

#endregion

#region Equipment callbacks

func UpdatePhysicalWeaponEquipment(w: QuantitySlot) -> void:
	for n in _model.RightHand.get_children():
		_model.RightHand.remove_child(n)
	for n in _model.LeftHand.get_children():
		_model.LeftHand.remove_child(n)
	var temp: PackedScene = w.item.item_equipped_model
	if temp != null:
		var model: Node3D = temp.instantiate()
		for child in model.get_children():
			if child is DamageSource: 
				var damageSource: DamageSource = child	
				damageSource.entity = self
				damageSource.attack_component = melee_attack_component
				damageSource.can_damage = true
				_model.RightHand.add_child(model)

func UpdatePhysicalArmorEquipment(_a: QuantitySlot) -> void:
	pass

func UpdatePhysicalAccessoryEquipment(_ac: QuantitySlot) -> void:
	pass

func _on_weapon_equipped(w: QuantitySlot) -> void:
	if w.item != null:
		#AnimTree.set("parameters/Moving Tree/Attack or Not/blend_amount",1.0)
		AnimTree["parameters/Moving Tree/Attack or Not/blend_amount"] = 1.0
	UpdatePhysicalWeaponEquipment(w)
	_update_granted_ability("weapon", w)
	_update_hud_all()
	
	var wd: WeaponData = equipment.equipped_weapon
	if wd.get_weapon_type_name() == "Melee":
		melee_attack_component.detection_range = wd.weapon_range
	elif wd.get_weapon_type_name() == "Ranged":
		ranged_attack_component.detection_range = wd.weapon_range

func _on_armor_equipped(a: QuantitySlot) -> void:
	UpdatePhysicalArmorEquipment(a)
	_update_granted_ability("armor", a)
	_update_hud_all()

func _on_accessory_equipped(ac: QuantitySlot) -> void:
	UpdatePhysicalAccessoryEquipment(ac)
	_update_granted_ability("accessory", ac)
	_update_hud_all()

func _on_slot_cleared(slot: String) -> void:
	# acts as unequipt signal
	if slot == "weapon":
		AnimTree.set("parameters/Moving Tree/Attack or Not/blend_amount",0.0)
	_remove_granted_ability(slot)
	_update_hud_all()
	
func _update_granted_ability(slot: String, item: QuantitySlot) -> void:
	_remove_granted_ability(slot)
	if item and item.item.granted_ability:
		var ab: AbilityData = item.item.granted_ability.duplicate()
		ability_list.add_ability(ab)
		_equipment_abilities[slot] = ab
		if ab.is_passive:
			passive_ability_list.add_ability(ab)

func _remove_granted_ability(slot: String) -> void:
	if _equipment_abilities.has(slot):
		var ab: AbilityData = _equipment_abilities[slot]
		ability_list.remove_ability(ab)
		if ab.is_passive:
			passive_ability_list.remove_ability(ab)
		_equipment_abilities.erase(slot)

#endregion

#region HUD helpers

func setState(state: PlayerState) -> void:
	PLAYER_STATE = state

func _update_hud_all() -> void:
	_hud.update_hp()

func _chat_window(otherInteracter: NPC) -> void:
	if PLAYER_STATE == PlayerState.DIALOG:
		_hud.Show_Text_Interact(self,otherInteracter)
	elif PLAYER_STATE == PlayerState.ACTIVE:
		_hud.Hide_Text_Interact()

func _vendor_window(otherInteracter: NPC, shoppinglist: Array[QuantitySlot] = []) -> void:
	if PLAYER_STATE == PlayerState.UI:
		_hud.Show_Text_Vendor(otherInteracter, shoppinglist)
	elif PLAYER_STATE == PlayerState.ACTIVE:
		_hud.Hide_Text_Vendor()

func ExitDialogeUI() -> void:
	PLAYER_STATE = PlayerState.ACTIVE
	_hud.Hide_Text_Interact()

#endregion

#region Consumable use

func heal(amount: float) -> void:
	health_component.heal(amount)
	_hud.show_notif("+%d HP restored" % int(amount), Color(0.3, 1.0, 0.4))

func update_hp() -> void:
	_hud.update_hp()

#endregion
