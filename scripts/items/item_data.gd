@tool
extends Resource
class_name ItemData

enum ItemType {
	WEAPON,
	ARMOR,
	ACCESSORY,
	CONSUMABLE
}

@export var item_name: String = "Unknown Item"
@export var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var stackable: bool = false
@export var max_stack: int = 1
@export var quantity: int = 1

## Assign a custom Texture2D here in the inspector to override the exported PNG.
@export var icon: Texture2D = null

## Optional ability granted while this item is equipped. Removed automatically on unequip.
@export var granted_ability: AbilityData = null

func get_tooltip() -> String:
	return "[b]" + item_name + "[/b]\n" + description

func get_type_color() -> Color:
	match item_type:
		ItemType.WEAPON:     return Color(1.0, 0.6, 0.1)
		ItemType.ARMOR:      return Color(0.3, 0.6, 1.0)
		ItemType.ACCESSORY:  return Color(0.8, 0.3, 1.0)
		ItemType.CONSUMABLE: return Color(0.3, 1.0, 0.4)
	return Color.WHITE

## Returns the icon — inspector override > exported PNG > missing-icon placeholder.
func get_icon() -> Texture2D:
	if icon:
		return icon
	var png_path := "res://resources/icons/" + item_name.to_lower().replace(" ", "_") + ".png"
	if ResourceLoader.exists(png_path):
		return ResourceLoader.load(png_path) as Texture2D
	return ItemData.missing_icon()

## Magenta/dark-magenta checkerboard — the classic "texture not found" signal.
static var _missing_icon_cache: ImageTexture = null
static func missing_icon() -> ImageTexture:
	if _missing_icon_cache:
		return _missing_icon_cache
	var sz  := 32
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var a   := Color(0.9, 0.0, 0.9, 1.0)  # bright magenta
	var b   := Color(0.3, 0.0, 0.3, 1.0)  # dark magenta
	for x in sz:
		for y in sz:
			img.set_pixel(x, y, a if (((x >> 3) + (y >> 3)) % 2 == 0) else b)
	_missing_icon_cache = ImageTexture.create_from_image(img)
	return _missing_icon_cache
