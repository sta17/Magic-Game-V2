@tool
extends RefCounted

## IconPainter — procedural pixel-art icon generator.
##
## All drawing code lives here, separated from item_data.gd so that items load
## pre-exported PNGs at runtime and only fall back to painting when no PNG exists.
##
## Used directly by export_icons.gd (File ▸ Run) to (re)generate
## res://resources/icons/*.png whenever the pixel art changes.


## Generate an icon for any ItemData (duck-typed to avoid circular dependency).
static func make_icon(item) -> ImageTexture:
	var sz  := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var col: Color = item.get_type_color()
	match item.item_name:
		"Pistol":        _draw_pistol(img, col, sz)
		"Assault Rifle": _draw_assault_rifle(img, col, sz)
		"Shotgun":       _draw_shotgun(img, col, sz)
		"Sniper Rifle":  _draw_sniper(img, col, sz)
		"Light Armor":   _draw_light_armor(img, col, sz)
		"Heavy Armor":   _draw_heavy_armor(img, col, sz)
		"Speed Boots":   _draw_boots(img, col, sz)
		"Power Glove":   _draw_glove(img, col, sz)
		"Medic Ring":    _draw_medic_ring(img, col, sz)
		_:
			# Fallback generic shapes: 0=WEAPON 1=ARMOR 2=ACCESSORY 3=CONSUMABLE
			match item.item_type:
				0: _draw_diamond(img, col, sz)
				1: _draw_round_rect(img, col, sz)
				2: _draw_ring(img, col, sz)
				3: _draw_cross(img, col, sz)
	return ImageTexture.create_from_image(_crop_to_content(img))


## Generate an icon for a ConsumableData (duck-typed).
## consumable_type: 0=MEDICINE  1=GRENADE
static func make_consumable_icon(item) -> ImageTexture:
	var sz  := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	match item.consumable_type:
		0: _draw_medkit_icon(img, sz)
		1: _draw_grenade_icon(img, sz)
	return ImageTexture.create_from_image(_crop_to_content(img))


# ── Helpers ────────────────────────────────────────────────────────────────────

static func _crop_to_content(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var min_x := w; var max_x := 0
	var min_y := h; var max_y := 0
	for x in w:
		for y in h:
			if img.get_pixel(x, y).a > 0.01:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y
	if max_x < min_x or max_y < min_y:
		return img
	var cw   := max_x - min_x + 1
	var ch   := max_y - min_y + 1
	var side := maxi(cw, ch)
	var out  := Image.create(side, side, false, Image.FORMAT_RGBA8)
	out.fill(Color.TRANSPARENT)
	out.blit_rect(img, Rect2i(min_x, min_y, cw, ch), Vector2i((side - cw) / 2, (side - ch) / 2))
	return out

static func _frect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	for px in range(maxi(x, 0), mini(x + w, iw)):
		for py in range(maxi(y, 0), mini(y + h, ih)):
			img.set_pixel(px, py, col)

static func _shade(col: Color, t: float) -> Color:
	return Color(col.r * t, col.g * t, col.b * t, 1.0)

static func _tint(col: Color, t: float) -> Color:
	return Color(minf(col.r + t, 1.0), minf(col.g + t, 1.0), minf(col.b + t, 1.0), 1.0)


# ── Per-item pixel-art icons ───────────────────────────────────────────────────

static func _draw_pistol(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.25)
	# Slide / barrel
	_frect(img, 8, 20, 46, 10, col)
	# Ejection port cutout
	_frect(img, 30, 22, 12, 4, d)
	# Muzzle tip
	_frect(img, 50, 22, 6, 6, col)
	_frect(img, 50, 23, 6, 4, d)
	# Hammer spur
	_frect(img, 8, 16, 6, 6, col)
	# Lower frame
	_frect(img, 8, 30, 22, 5, col)
	# Grip
	_frect(img, 9, 35, 13, 21, col)
	_frect(img, 11, 39, 9, 3, d)
	_frect(img, 11, 44, 9, 3, d)
	_frect(img, 11, 49, 9, 3, d)
	# Trigger guard
	_frect(img, 23, 30, 10, 3, col)
	_frect(img, 31, 30, 3, 12, col)
	_frect(img, 23, 40, 10, 3, col)
	# Trigger
	_frect(img, 26, 33, 3, 9, d)
	# Slide highlight
	_frect(img, 10, 21, 18, 2, l)

static func _draw_assault_rifle(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.25)
	# Stock
	_frect(img, 4, 26, 10, 14, col)
	_frect(img, 4, 30, 10, 4, d)
	# Upper receiver
	_frect(img, 14, 22, 28, 8, col)
	# Barrel
	_frect(img, 42, 25, 16, 5, col)
	_frect(img, 42, 26, 16, 3, d)
	# Flash hider
	_frect(img, 56, 24, 4, 7, col)
	_frect(img, 57, 25, 2, 5, d)
	# Lower receiver
	_frect(img, 14, 30, 30, 6, col)
	# Pistol grip
	_frect(img, 30, 36, 8, 16, col)
	_frect(img, 31, 39, 6, 3, d)
	_frect(img, 31, 44, 6, 3, d)
	# Magazine
	_frect(img, 18, 30, 10, 22, col)
	_frect(img, 19, 32, 8, 19, d)
	# Trigger
	_frect(img, 28, 32, 3, 10, d)
	# Trigger guard
	_frect(img, 26, 36, 6, 3, col)
	_frect(img, 38, 36, 3, 8, col)
	_frect(img, 26, 42, 14, 3, col)
	# Scope rail
	_frect(img, 16, 18, 22, 4, col)
	_frect(img, 16, 19, 22, 2, d)
	# Charging handle
	_frect(img, 39, 22, 4, 5, l)

static func _draw_shotgun(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.25)
	# Stock
	_frect(img, 4, 24, 12, 16, col)
	_frect(img, 4, 28, 12, 4, d)
	# Receiver
	_frect(img, 16, 22, 18, 18, col)
	# Barrel (thick, double-barrel hint)
	_frect(img, 34, 22, 24, 13, col)
	_frect(img, 35, 24, 22, 4, d)
	_frect(img, 35, 29, 22, 4, d)
	# Muzzle
	_frect(img, 56, 23, 4, 9, d)
	# Pump / foregrip
	_frect(img, 36, 35, 16, 8, col)
	_frect(img, 37, 36, 14, 6, d)
	# Trigger
	_frect(img, 24, 30, 3, 10, d)
	# Trigger guard
	_frect(img, 22, 28, 12, 3, col)
	_frect(img, 32, 28, 3, 12, col)
	_frect(img, 22, 38, 12, 3, col)
	# Ejection port
	_frect(img, 18, 24, 8, 4, d)
	# Highlight
	_frect(img, 36, 23, 16, 2, l)

static func _draw_sniper(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.25)
	# Stock
	_frect(img, 4, 26, 10, 14, col)
	_frect(img, 4, 30, 10, 4, d)
	# Receiver body
	_frect(img, 14, 24, 22, 12, col)
	# Pistol grip
	_frect(img, 28, 34, 8, 14, col)
	_frect(img, 29, 37, 6, 3, d)
	_frect(img, 29, 42, 6, 3, d)
	# Barrel (long, thin)
	_frect(img, 36, 27, 22, 5, col)
	_frect(img, 36, 28, 22, 3, d)
	# Muzzle brake
	_frect(img, 56, 25, 5, 9, col)
	_frect(img, 57, 26, 3, 7, d)
	# Scope tube
	_frect(img, 16, 16, 28, 8, col)
	_frect(img, 17, 17, 26, 6, d)
	_frect(img, 18, 18, 8, 4, l)
	_frect(img, 34, 18, 8, 4, l)
	# Scope mounts
	_frect(img, 18, 23, 4, 4, col)
	_frect(img, 34, 23, 4, 4, col)
	# Trigger guard
	_frect(img, 20, 28, 10, 3, col)
	_frect(img, 28, 28, 3, 12, col)
	_frect(img, 20, 38, 10, 3, col)
	# Trigger
	_frect(img, 22, 31, 3, 9, d)
	# Bipod
	_frect(img, 48, 31, 3, 16, col)
	_frect(img, 54, 31, 3, 16, col)

static func _draw_light_armor(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.25)
	# Shoulder guards
	_frect(img, 6, 10, 14, 20, col)
	_frect(img, 6, 28, 14, 5, d)
	_frect(img, 44, 10, 14, 20, col)
	_frect(img, 44, 28, 14, 5, d)
	# Collar
	_frect(img, 18, 10, 8, 10, col)
	_frect(img, 38, 10, 8, 10, col)
	# Main chest plate
	_frect(img, 18, 18, 28, 34, col)
	# Center ridge
	_frect(img, 30, 20, 4, 30, d)
	# Top trim
	_frect(img, 8, 10, 10, 3, l)
	_frect(img, 46, 10, 10, 3, l)
	_frect(img, 20, 18, 24, 3, l)
	# Strap attachment points
	_frect(img, 22, 6, 6, 6, col)
	_frect(img, 36, 6, 6, 6, col)

static func _draw_heavy_armor(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.25)
	# Large shoulder pauldrons
	_frect(img, 4, 8, 16, 26, col)
	_frect(img, 4, 30, 16, 6, d)
	_frect(img, 44, 8, 16, 26, col)
	_frect(img, 44, 30, 16, 6, d)
	# Collar sections
	_frect(img, 18, 8, 10, 8, col)
	_frect(img, 36, 8, 10, 8, col)
	# Main chest plate
	_frect(img, 18, 14, 28, 38, col)
	# Belly plates
	_frect(img, 18, 50, 12, 8, col)
	_frect(img, 34, 50, 12, 8, col)
	# Center seam
	_frect(img, 30, 16, 4, 44, d)
	# Trim
	_frect(img, 6, 8, 12, 4, l)
	_frect(img, 46, 8, 12, 4, l)
	_frect(img, 20, 14, 24, 4, l)
	# Rivet details
	for row in [22, 30, 38, 46]:
		_frect(img, 22, row, 4, 4, d)
		_frect(img, 38, row, 4, 4, d)

static func _draw_boots(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.25)
	# Boot shaft
	_frect(img, 16, 8, 20, 30, col)
	# Ankle flare
	_frect(img, 12, 36, 26, 8, col)
	# Foot / sole
	_frect(img, 10, 42, 42, 12, col)
	_frect(img, 10, 52, 42, 4, d)
	# Toe cap
	_frect(img, 46, 44, 6, 10, col)
	_frect(img, 46, 52, 6, 4, d)
	# Shaft top opening
	_frect(img, 18, 8, 16, 4, d)
	# Lace rows
	_frect(img, 18, 16, 16, 2, l)
	_frect(img, 18, 22, 16, 2, l)
	_frect(img, 18, 28, 16, 2, l)
	# Speed lines
	_frect(img, 50, 26, 10, 3, l)
	_frect(img, 52, 32, 8, 3, l)
	_frect(img, 54, 38, 6, 3, l)

static func _draw_glove(img: Image, col: Color, sz: int) -> void:
	var d := _shade(col, 0.55)
	var l := _tint(col, 0.5)
	# Palm
	_frect(img, 14, 28, 36, 28, col)
	# Fingers: index, middle, ring, pinky
	_frect(img, 14, 8, 8, 22, col)
	_frect(img, 24, 6, 8, 24, col)
	_frect(img, 34, 8, 8, 22, col)
	_frect(img, 44, 14, 8, 16, col)
	# Thumb
	_frect(img, 6, 32, 10, 10, col)
	# Knuckle highlights
	_frect(img, 15, 29, 5, 3, l)
	_frect(img, 25, 29, 5, 3, l)
	_frect(img, 35, 29, 5, 3, l)
	_frect(img, 45, 29, 5, 3, l)
	# Power crystal in palm
	_frect(img, 20, 38, 24, 12, d)
	_frect(img, 24, 40, 16, 8, l)
	# Wrist band
	_frect(img, 14, 54, 36, 4, d)

static func _draw_medic_ring(img: Image, col: Color, sz: int) -> void:
	var c      := sz / 2
	var r_outer := c - 4.0
	var r_inner := c - 16.0
	# Ring band
	for x in sz:
		for y in sz:
			var d2 := float((x - c) * (x - c) + (y - c) * (y - c))
			if d2 <= r_outer * r_outer and d2 >= r_inner * r_inner:
				img.set_pixel(x, y, col)
	# Medical cross
	var cross := Color(1.0, 0.95, 0.95, 1.0)
	_frect(img, c - 10, c - 3, 20, 6, cross)
	_frect(img, c - 3, c - 10, 6, 20, cross)


# ── Generic fallback shapes ────────────────────────────────────────────────────

static func _draw_diamond(img: Image, col: Color, sz: int) -> void:
	var c := sz * 0.5
	var r := c - 5.0
	for x in sz:
		for y in sz:
			if absf(x - c) + absf(y - c) <= r:
				img.set_pixel(x, y, col)

static func _draw_round_rect(img: Image, col: Color, sz: int) -> void:
	var margin   := 8
	var corner_r := 10.0
	var cx1      := float(margin) + corner_r
	var cx2      := float(sz - margin) - corner_r
	var cy1      := float(margin) + corner_r
	var cy2      := float(sz - margin) - corner_r
	for x in sz:
		for y in sz:
			var fx := float(x)
			var fy := float(y)
			if fx < margin or fx > sz - 1 - margin or fy < margin or fy > sz - 1 - margin:
				continue
			var in_left  := fx < cx1
			var in_right := fx > cx2
			var in_top   := fy < cy1
			var in_bot   := fy > cy2
			if (in_left or in_right) and (in_top or in_bot):
				var ncx := cx1 if in_left else cx2
				var ncy := cy1 if in_top  else cy2
				if (fx - ncx) * (fx - ncx) + (fy - ncy) * (fy - ncy) > corner_r * corner_r:
					continue
			img.set_pixel(x, y, col)

static func _draw_ring(img: Image, col: Color, sz: int) -> void:
	var c       := sz * 0.5
	var r_outer := c - 4.0
	var r_inner := c - 16.0
	for x in sz:
		for y in sz:
			var d2 := (x - c) * (x - c) + (y - c) * (y - c)
			if d2 <= r_outer * r_outer and d2 >= r_inner * r_inner:
				img.set_pixel(x, y, col)

static func _draw_cross(img: Image, col: Color, sz: int) -> void:
	var arm    := sz / 3
	var margin := (sz - arm) / 2
	for x in sz:
		for y in sz:
			if (y >= margin and y < sz - margin) or (x >= margin and x < sz - margin):
				img.set_pixel(x, y, col)

static func _draw_circle(img: Image, col: Color, sz: int) -> void:
	var c := sz * 0.5
	var r := c - 5.0
	for x in sz:
		for y in sz:
			if (x - c) * (x - c) + (y - c) * (y - c) <= r * r:
				img.set_pixel(x, y, col)


# ── Consumable icons ───────────────────────────────────────────────────────────

static func _draw_medkit_icon(img: Image, sz: int) -> void:
	var green := Color(0.25, 0.85, 0.35, 1.0)
	var dark  := Color(0.15, 0.50, 0.20, 1.0)
	var white := Color(0.95, 0.95, 0.95, 1.0)
	var red   := Color(0.90, 0.15, 0.15, 1.0)
	# Case body
	_frect(img, 8, 14, 48, 38, green)
	# Handle
	_frect(img, 22, 6, 20, 10, green)
	_frect(img, 24, 7, 16, 6, dark)
	# Lid divide
	_frect(img, 8, 28, 48, 3, dark)
	# White cross background panel
	_frect(img, 18, 18, 28, 26, white)
	# Red cross
	_frect(img, 20, 28, 24, 8, red)
	_frect(img, 28, 20, 8, 24, red)
	# Case corner trim
	_frect(img, 8, 14, 48, 3, Color(0.35, 0.95, 0.45, 1.0))

static func _draw_grenade_icon(img: Image, sz: int) -> void:
	var body      := Color(0.60, 0.72, 0.28, 1.0)
	var body_dark := Color(0.38, 0.48, 0.18, 1.0)
	var grey      := Color(0.60, 0.60, 0.60, 1.0)
	var dark_grey := Color(0.35, 0.35, 0.35, 1.0)
	# Main oval body
	_frect(img, 16, 20, 32, 32, body)
	_frect(img, 12, 28, 40, 16, body)
	_frect(img, 14, 24, 36, 24, body)
	# Pineapple grid lines
	for i in range(3):
		_frect(img, 14, 28 + i * 8, 36, 2, body_dark)
	for i in range(4):
		_frect(img, 18 + i * 8, 22, 2, 30, body_dark)
	# Safety cap (top)
	_frect(img, 24, 12, 16, 10, grey)
	_frect(img, 26, 10, 12, 4, dark_grey)
	# Fuse cord
	_frect(img, 30, 6, 4, 6, grey)
	# Safety pin ring
	_frect(img, 40, 14, 8, 4, grey)
	_frect(img, 46, 10, 2, 10, grey)
	# Safety lever
	_frect(img, 18, 17, 14, 4, grey)
