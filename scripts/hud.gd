extends Control
## In-game HUD, built in code since everything is data-driven.

const INK := Color(0.176, 0.204, 0.212)
const AMBER := Color(0.839, 0.537, 0.063)

const HEART := preload("res://assets/heart.png")
const HEART_EMPTY := preload("res://assets/heart_empty.png")
const ARROW := preload("res://assets/arrow.png")
const LABEL_SCORE := preload("res://assets/ui_score.png")
const LABEL_WAVE := preload("res://assets/ui_wave.png")
const LABEL_TIME := preload("res://assets/ui_time.png")

@onready var game: Node = get_node("/root/Main")

var _score_value: PaintedNumber
var _wave_value: PaintedNumber
var _time_value: PaintedNumber
var _dash_label: Label
var _power_label: Label
var _banner: Label
var _hearts: Array[TextureRect] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_add_painted(LABEL_SCORE, Vector2(68, 34), 100)
	_add_painted(LABEL_WAVE, Vector2(68, 82), 100)
	_add_painted(LABEL_TIME, Vector2(68, 130), 100)
	_score_value = _add_number(Vector2(128, 34))
	_wave_value = _add_number(Vector2(128, 82))
	_time_value = _add_number(Vector2(128, 130))
	_time_value.value = 30

	for i in 3:
		var h := TextureRect.new()
		h.texture = HEART
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.position = Vector2(960 - 32 - i * 28 - 12, 26 - 12)
		h.size = Vector2(24, 24)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h)
		_hearts.append(h)

	_dash_label = _add_label("DASH READY", Vector2(16, 607), 20, INK, false)
	_power_label = _add_label("", Vector2(16, 581), 20, AMBER, false)

	_banner = Label.new()
	_banner.text = "WAVE 1"
	_banner.position = Vector2(0, 210)
	_banner.size = Vector2(960, 60)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 44)
	_banner.add_theme_color_override("font_color", INK)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)


func _add_painted(tex: Texture2D, center: Vector2, sz: float) -> void:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.position = center - Vector2(sz, sz) / 2.0
	r.size = Vector2(sz, sz)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


func _add_number(center_left: Vector2, h := 36.0) -> PaintedNumber:
	var n := PaintedNumber.new()
	n.digit_height = h
	n.position = center_left - Vector2(0, 17)
	n.size = Vector2(320, 34)
	add_child(n)
	return n


func _add_label(text: String, pos: Vector2, font_size: int, color: Color, centered_y := true) -> Label:
	var l := Label.new()
	l.text = text
	l.size = Vector2(320, 34)
	l.position = pos - (Vector2(0, 17) if centered_y else Vector2.ZERO)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func update_hud() -> void:
	if game.player == null:
		return
	_score_value.value = game.score
	_wave_value.value = game.wave
	_time_value.value = maxi(0, ceili(game.wave_timer))

	for i in _hearts.size():
		_hearts[i].texture = HEART if i < game.player.lives else HEART_EMPTY

	if game.player.dash_cooldown > 0:
		_dash_label.text = "DASH %.1fs" % game.player.dash_cooldown
	else:
		_dash_label.text = "DASH READY"

	if game.player.power != "":
		var t := "" if game.player.power == "shield" else " %ds" % ceili(game.player.power_time)
		_power_label.text = game.player.power.to_upper() + t
	else:
		_power_label.text = ""

	_banner.visible = game.wave_banner > 0
	_banner.text = "WAVE %d" % game.wave
	_banner.modulate.a = clampf(game.wave_banner, 0, 1)

	queue_redraw()


# edge arrows pointing at off-screen snake heads
func _draw() -> void:
	if game.player == null:
		return
	var m := 28.0
	var xform: Transform2D = game.get_viewport().get_canvas_transform()
	for s in game.alive_snakes():
		var sp: Vector2 = xform * s.head
		if sp.x >= 0 and sp.x <= 960 and sp.y >= 0 and sp.y <= 640:
			continue
		var ip := Vector2(clampf(sp.x, m, 960 - m), clampf(sp.y, m, 640 - m))
		var ang := (sp - ip).angle()
		draw_set_transform(ip, ang - PI / 2, Vector2.ONE)  # painted arrow points down
		draw_texture_rect(ARROW, Rect2(Vector2(-15, -15), Vector2(30, 30)), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
