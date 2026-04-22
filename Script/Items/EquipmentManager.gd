@icon("res://Assets/Icons/Pixel-Boy/control/icon_money_bag.png")
extends Resource
class_name EquipmentManager

signal weapon_equipped(weapon: QuantitySlot)
signal armor_equipped(armor: QuantitySlot)
signal accessory_equipped(accessory: QuantitySlot)
signal slot_cleared(slot: String)

var equipped_weapon: WeaponData    = null
var equipped_weapon_wrapper: QuantitySlot    = null
var equipped_armor: ArmorData      = null
var equipped_armor_wrapper: QuantitySlot      = null
var equipped_accessory: AccessoryData = null
var equipped_accessory_wrapper: QuantitySlot = null

#region Equip and Unequip
func equip_itemNew(from_slot: InventorySlot, to_slot: InventorySlot,inv1:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	var to_item:QuantitySlot = to_slot.itemQuantity
	
	if handle_equip(from_item):
		if to_item == null:
			if inv1.remove_item_at_index(from_slot.index):
				inv1.inventory_changed.emit()
				return true
		else:
			if inv1.add_item_at_index(to_item,from_slot.index):
				inv1.inventory_changed.emit()
				return true
			else:
				handle_equip(to_item)
				return false
	return false

func handle_equip(item: QuantitySlot) -> bool:
	match item.item.item_type:
		ItemData.ItemType.WEAPON:
			_equip_weapon(item)
			return true
		ItemData.ItemType.ARMOR:
			_equip_armor(item)
			return true
		ItemData.ItemType.ACCESSORY:
			_equip_accessory(item)
			return true
	return false

## Equip any item into its matching slot. Returns the previously equipped item (or null).
func equip_item(item: QuantitySlot) -> QuantitySlot:
	match item.item.item_type:
		ItemData.ItemType.WEAPON:
			return _equip_weapon(item)
		ItemData.ItemType.ARMOR:
			return _equip_armor(item)
		ItemData.ItemType.ACCESSORY:
			return _equip_accessory(item)
	return null

func _equip_weapon(weapon: QuantitySlot) -> QuantitySlot:
	var old: QuantitySlot = equipped_weapon_wrapper
	equipped_weapon = weapon.item as WeaponData
	equipped_weapon_wrapper = weapon
	weapon_equipped.emit(equipped_weapon_wrapper)
	return old

func _equip_armor(armor: QuantitySlot) -> QuantitySlot:
	var old: QuantitySlot = equipped_armor_wrapper
	equipped_armor = armor.item as ArmorData
	equipped_armor_wrapper = armor
	armor_equipped.emit(equipped_armor_wrapper)
	return old

func _equip_accessory(accessory: QuantitySlot) -> QuantitySlot:
	var old: QuantitySlot = equipped_accessory_wrapper
	equipped_accessory = accessory.item as AccessoryData
	equipped_accessory_wrapper = accessory
	accessory_equipped.emit(equipped_accessory_wrapper)
	return old

func unequip_itemNew(from_slot: InventorySlot, to_slot: InventorySlot,inv1:Inventory) -> bool:
	var from_item:QuantitySlot = from_slot.itemQuantity
	var to_item:QuantitySlot = to_slot.itemQuantity
	
	if handle_unequip(from_item):
		if to_item == null:
			if inv1.add_item_at_index(from_item,to_slot.index-1):
				inv1.inventory_changed.emit()
				return true
			else:
				handle_equip(from_item)
				return false
		else:
			if from_slot.item.item_type == to_slot.item.item_type:
				equip_itemNew(from_slot, to_slot,inv1)
				inv1.add_item_at_index(to_item,to_slot.index)
				inv1.inventory_changed.emit()
				return true
			else:
				handle_equip(from_item)
				return false
	return false

func handle_unequip(item: QuantitySlot) -> bool:
	match item.item.item_type:
		ItemData.ItemType.WEAPON:
			unequip_weapon()
			return true
		ItemData.ItemType.ARMOR:
			unequip_armor()
			return true
		ItemData.ItemType.ACCESSORY:
			unequip_accessory()
			return true
	return false

func unequip_weapon() -> QuantitySlot:
	var old: QuantitySlot = equipped_weapon_wrapper
	equipped_weapon = null
	equipped_weapon_wrapper = null
	slot_cleared.emit("weapon")
	return old

func unequip_armor() -> QuantitySlot:
	var old: QuantitySlot = equipped_armor_wrapper
	equipped_armor = null
	equipped_armor_wrapper = null
	slot_cleared.emit("armor")
	return old

func unequip_accessory() -> QuantitySlot:
	var old: QuantitySlot = equipped_accessory_wrapper
	equipped_accessory = null
	equipped_accessory_wrapper = null
	slot_cleared.emit("accessory")
	return old

#endregion

#region Get Stats
func get_defense() -> float:
	return equipped_armor.defense if equipped_armor else 0.0

func get_health_bonus() -> float:
	return equipped_armor.max_health_bonus if equipped_armor else 0.0

func get_speed_bonus() -> float:
	return equipped_accessory.speed_bonus if equipped_accessory else 0.0

func get_damage_bonus() -> float:
	return equipped_accessory.damage_bonus if equipped_accessory else 0.0

func get_health_regen() -> float:
	return equipped_accessory.health_regen if equipped_accessory else 0.0
#endregion

#region Misc

func is_equipped(item: ItemData) -> bool:
	return item == equipped_weapon or item == equipped_armor or item == equipped_accessory
	
func is_equipped_wrapper(slot: QuantitySlot) -> bool:
	return slot == equipped_weapon_wrapper or slot == equipped_armor_wrapper or slot == equipped_accessory_wrapper

#endregion
