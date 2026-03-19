## export_icons.gd — EditorScript
##
## HOW TO USE:
##   1. Open this file in Godot's Script Editor.
##   2. Click  File ▸ Run  (or the small ▶ button at the top-right of the editor).
##   3. PNGs are written to  res://resources/icons/
##   4. After it finishes, click  Project ▸ Reimport Resources  (or just reopen
##      the project) so Godot picks up the new files.
##
## You can re-run whenever you change a drawing function in icon_painter.gd
## to refresh the PNGs.  The script calls IconPainter directly so it always
## regenerates from source, regardless of any existing PNG files.

@tool
extends EditorScript

const OUTPUT_DIR    := "res://resources/icons/"
const IconPainter   := preload("res://tools/icon_painter.gd")
const WeaponData    := preload("res://scripts/items/weapon_data.gd")
const ArmorData     := preload("res://scripts/items/armor_data.gd")
const AccessoryData := preload("res://scripts/items/accessory_data.gd")
const MedicineData  := preload("res://scripts/items/medicine_data.gd")
const GrenadeData   := preload("res://scripts/items/grenade_data.gd")

func _run() -> void:
	# Make sure the output folder exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	# ── Weapons ───────────────────────────────────────────────────────────────
	for name in ["Pistol", "Assault Rifle", "Shotgun", "Sniper Rifle"]:
		var w := WeaponData.new()
		w.item_name = name
		_save(IconPainter.make_icon(w), name)

	# ── Armor ─────────────────────────────────────────────────────────────────
	for name in ["Light Armor", "Heavy Armor"]:
		var a := ArmorData.new()
		a.item_name = name
		_save(IconPainter.make_icon(a), name)

	# ── Accessories ───────────────────────────────────────────────────────────
	for name in ["Speed Boots", "Power Glove", "Medic Ring"]:
		var ac := AccessoryData.new()
		ac.item_name = name
		_save(IconPainter.make_icon(ac), name)

	# ── Consumables ───────────────────────────────────────────────────────────
	var medkit := MedicineData.new()
	medkit.item_name = "Medkit"
	_save(IconPainter.make_consumable_icon(medkit), "Medkit")

	var grenade := GrenadeData.new()
	grenade.item_name = "Grenade"
	_save(IconPainter.make_consumable_icon(grenade), "Grenade")

	# ── Done ─────────────────────────────────────────────────────────────────
	print("export_icons: all done → ", ProjectSettings.globalize_path(OUTPUT_DIR))
	# Ask the editor to scan so the new files appear in the FileSystem dock.
	get_editor_interface().get_resource_filesystem().scan()


func _save(tex: Texture2D, item_name: String) -> void:
	if tex == null:
		push_error("export_icons: null texture for '%s'" % item_name)
		return

	var img: Image
	if tex is ImageTexture:
		img = (tex as ImageTexture).get_image()
	else:
		push_error("export_icons: unexpected texture type for '%s'" % item_name)
		return

	var filename := item_name.to_lower().replace(" ", "_") + ".png"
	var abs_path := ProjectSettings.globalize_path(OUTPUT_DIR) + filename
	var err := img.save_png(abs_path)
	if err == OK:
		print("  saved: " + filename)
	else:
		push_error("export_icons: failed to save '%s' (error %d)" % [filename, err])
