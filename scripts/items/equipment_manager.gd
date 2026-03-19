extends Node
class_name EquipmentManager

signal weapon_equipped(weapon: WeaponData)
signal armor_equipped(armor: ArmorData)
signal accessory_equipped(accessory: AccessoryData)
signal slot_cleared(slot: String)

var equipped_weapon: WeaponData    = null
var equipped_armor: ArmorData      = null
var equipped_accessory: AccessoryData = null

## Equip any item into its matching slot. Returns the previously equipped item (or null).
func equip_item(item: ItemData) -> ItemData:
	match item.item_type:
		ItemData.ItemType.WEAPON:
			return _equip_weapon(item as WeaponData)
		ItemData.ItemType.ARMOR:
			return _equip_armor(item as ArmorData)
		ItemData.ItemType.ACCESSORY:
			return _equip_accessory(item as AccessoryData)
	return null

func _equip_weapon(weapon: WeaponData) -> ItemData:
	var old = equipped_weapon
	equipped_weapon = weapon
	weapon_equipped.emit(weapon)
	return old

func _equip_armor(armor: ArmorData) -> ItemData:
	var old = equipped_armor
	equipped_armor = armor
	armor_equipped.emit(armor)
	return old

func _equip_accessory(accessory: AccessoryData) -> ItemData:
	var old = equipped_accessory
	equipped_accessory = accessory
	accessory_equipped.emit(accessory)
	return old

func unequip_weapon() -> WeaponData:
	var old = equipped_weapon
	equipped_weapon = null
	slot_cleared.emit("weapon")
	return old

func unequip_armor() -> ArmorData:
	var old = equipped_armor
	equipped_armor = null
	slot_cleared.emit("armor")
	return old

func unequip_accessory() -> AccessoryData:
	var old = equipped_accessory
	equipped_accessory = null
	slot_cleared.emit("accessory")
	return old

## Stat helpers
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

func is_equipped(item: ItemData) -> bool:
	return item == equipped_weapon or item == equipped_armor or item == equipped_accessory
