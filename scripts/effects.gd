extends Node2D
## Particle bursts and popups, all drawn by this one node.

const CRITTERS: Array[Texture2D] = [
	preload("res://assets/critter_circle.png"),
	preload("res://assets/critter_square.png"),
	preload("res://assets/critter_triangle.png"),
	preload("res://assets/critter_pentagon.png"),
	preload("res://assets/critter_diamond.png"),
]

var particles: Array[Dictionary] = []
var popups: Array[Dictionary] = []


# one-shot sprite popup: pops in, floats up, fades out
func popup(pos: Vector2, tex: Texture2D, size := 96.0) -> void:
	popups.append({
		"pos": pos,
		"tex": tex,
		"size": size,
		"life": 0.7,
		"max_life": 0.7,
	})


# color kept for call sites; critter sprites are drawn untinted
func burst(pos: Vector2, _color: Color, count: int) -> void:
	for i in count:
		var a := randf() * TAU
		var sp := 60.0 + randf() * 180.0
		var life := 0.4 + randf() * 0.4
		particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(a) * sp,
			"life": life,
			"max_life": life,
			"tex": CRITTERS[randi() % CRITTERS.size()],
			"rot": randf() * TAU,
			"spin": (randf() - 0.5) * 12.0,
		})


func update(dt: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p.pos += p.vel * dt
		p.vel *= 0.92
		p.rot += p.spin * dt
		p.life -= dt
		if p.life <= 0:
			particles.remove_at(i)
	for i in range(popups.size() - 1, -1, -1):
		var p := popups[i]
		p.pos += Vector2(0, -26) * dt
		p.life -= dt
		if p.life <= 0:
			popups.remove_at(i)
	queue_redraw()


func clear() -> void:
	particles.clear()
	popups.clear()
	queue_redraw()


func _draw() -> void:
	for p in particles:
		var alpha: float = maxf(0, p.life / p.max_life)
		draw_set_transform(p.pos, p.rot, Vector2.ONE)
		draw_texture_rect(p.tex, Rect2(Vector2(-6, -6), Vector2(12, 12)), false,
				Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in popups:
		var age: float = p.max_life - p.life
		var pop: float = minf(1.0, age * 10.0)
		var alpha: float = minf(1.0, p.life / p.max_life * 2.5)
		var sz: float = p.size * pop
		draw_texture_rect(p.tex, Rect2(p.pos - Vector2(sz, sz) / 2.0, Vector2(sz, sz)),
				false, Color(1, 1, 1, alpha))
