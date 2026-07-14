class_name PaintedNumber
extends Control
## Draws an integer using the hand-painted digit sprites instead of a font.

const DIGITS: Array[Texture2D] = [
	preload("res://assets/digit_0.png"),
	preload("res://assets/digit_1.png"),
	preload("res://assets/digit_2.png"),
	preload("res://assets/digit_3.png"),
	preload("res://assets/digit_4.png"),
	preload("res://assets/digit_5.png"),
	preload("res://assets/digit_6.png"),
	preload("res://assets/digit_7.png"),
	preload("res://assets/digit_8.png"),
	preload("res://assets/digit_9.png"),
]

const SPACING := 0.12        # gap between digits, fraction of height

@export var digit_height := 26.0
@export var centered := false

var value := 0:
	set(v):
		if value != v:
			value = v
			queue_redraw()

# per-instance seed so every counter rolls its own colors, stable per session
var _hue_seed := randf()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var text := str(value)
	var widths: Array[float] = []
	var total := 0.0
	for ch in text:
		var tex := DIGITS[int(ch)]
		var w := digit_height * tex.get_width() / tex.get_height()
		widths.append(w)
		total += w
	total += digit_height * SPACING * (text.length() - 1)

	var x := (size.x - total) / 2.0 if centered else 0.0
	var y := (size.y - digit_height) / 2.0
	for i in text.length():
		# each slot gets its own paint color, mixed from the digit shown
		# there so it stays put between frames
		var hue := fposmod(_hue_seed + i * 0.371 + int(text[i]) * 0.113, 1.0)
		var col := Color.from_hsv(hue, 0.8, 0.85)
		draw_texture_rect(DIGITS[int(text[i])],
				Rect2(Vector2(x, y), Vector2(widths[i], digit_height)), false, col)
		x += widths[i] + digit_height * SPACING
