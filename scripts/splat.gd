class_name SplatStain
extends Node2D
## the paint splat

var splat_size := 75.0 + randf() * 35.0
var max_life := 9.0
var life := 9.0
var dead := false

var _rot := randf() * TAU
var _tex: Texture2D = preload("res://assets/splat.png")
var _tint := Color.WHITE


# reuse the stain fade for other art (ant / critter squishes)
func set_look(tex: Texture2D, size: float, tint := Color.WHITE) -> void:
	_tex = tex
	splat_size = size * (0.9 + randf() * 0.25)
	_tint = tint


func update(dt: float) -> void:
	life -= dt
	if life <= 0:
		dead = true
		queue_free()
	queue_redraw()


func _draw() -> void:
	var age := max_life - life
	var pop := minf(1.0, age * 7.0)                       # quick pop-in
	var alpha := minf(0.9, life / max_life * 1.8)         # slow fade-out
	draw_set_transform(Vector2.ZERO, _rot, Vector2.ONE)
	Util.draw_sprite(self, _tex, Vector2.ZERO, splat_size * pop,
			Color(_tint.r, _tint.g, _tint.b, alpha))
