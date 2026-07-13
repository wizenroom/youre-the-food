extends Node2D
## Faint grid over the whole world.

const WORLD_W := 2880.0
const WORLD_H := 1920.0


func _draw() -> void:
	var col := Color(0, 0, 0, 0.05)
	var x := 0.0
	while x <= WORLD_W:
		draw_line(Vector2(x, 0), Vector2(x, WORLD_H), col, 1.0)
		x += 40.0
	var y := 0.0
	while y <= WORLD_H:
		draw_line(Vector2(0, y), Vector2(WORLD_W, y), col, 1.0)
		y += 40.0
