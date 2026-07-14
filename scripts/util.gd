class_name Util

static var shadows_enabled := true

static var _shadow_tex: GradientTexture2D


#shadow
static func shadow_tex() -> Texture2D:
	if _shadow_tex == null:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 1.0])
		grad.colors = PackedColorArray([
			Color(0.07, 0.063, 0.055, 0.42),
			Color(0.07, 0.063, 0.055, 0.30),
			Color(0.07, 0.063, 0.055, 0.14),
			Color(0.07, 0.063, 0.055, 0.0),
		])
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 128
		tex.height = 128
		_shadow_tex = tex
	return _shadow_tex


# centered at pos
static func draw_sprite(ci: CanvasItem, tex: Texture2D, pos: Vector2, size: float, mod: Color = Color.WHITE) -> void:
	ci.draw_texture_rect(tex, Rect2(pos - Vector2(size, size) / 2.0, Vector2(size, size)), false, mod)


# 2 layer shadow
static func draw_shadow(ci: CanvasItem, pos: Vector2, size: float, strength := 1.0, mod:Color = Color.WHITE) -> void:
	if not shadows_enabled:
		return
	var tex := shadow_tex()
	var o := pos + Vector2(size * 0.12, size * 0.34)
	var ambient := Vector2(size * 1.6, size * 0.7)
	var contact := Vector2(size * 0.95, size * 0.4)
	ci.draw_texture_rect(tex, Rect2(o - ambient / 2.0, ambient), false, Color(mod.r,mod.g, mod.b, 0.75 * strength))
	var co := o - Vector2(size * 0.04, size * 0.02)
	ci.draw_texture_rect(tex, Rect2(co - contact / 2.0, contact), false, Color(mod.r,mod.g, mod.b, 0.85 * strength))
