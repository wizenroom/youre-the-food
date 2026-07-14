class_name SpikeTrap
extends Node2D
## A telegraphed row of spikes. An exclamation mark and arrows warn at the
## origin, then spikes erupt outward along each arrow, one after another.

const TELEGRAPH := 1.2        # warning time before the first spike
const SPACING := 70.0         # gap between spikes along the row
const ERUPT_STAGGER := 0.09   # delay between neighbours, so the row travels
const RISE_TIME := 0.16
const STAND_TIME := 2.8       # measured from each spike's own eruption
const BREAK_TIME := 0.55
const HURT_RADIUS := 15.0     # touching a standing spike
const ERUPT_RADIUS := 30.0    # popping up underneath something
const DRAW_SIZE := 96.0

const GREEN := Color("2ed573")

const TEX_SPIKE := preload("res://assets/spike.png")
const TEX_BROKEN := preload("res://assets/spike_broken.png")
const TEX_WARN := preload("res://assets/spike_warn.png")
const TEX_ARROW := preload("res://assets/spike_arrow.png")

var game: Node
var dead := false

var _timer := 0.0
var _dirs: Array[Vector2] = []
# each spike: off, delay, state ("waiting"/"up"/"breaking"), age, break_age
var _spikes: Array[Dictionary] = []


func setup(g: Node, dirs: Array[Vector2], count := 5) -> void:
	game = g
	_dirs = dirs
	_spikes.append({"off": Vector2.ZERO, "delay": 0.0, "state": "waiting",
			"age": 0.0, "break_age": 0.0})
	for d in dirs:
		for i in range(1, count + 1):
			var off: Vector2 = d * SPACING * i
			var wp := position + off
			if wp.x < 50 or wp.x > game.WORLD_W - 50 \
					or wp.y < 50 or wp.y > game.WORLD_H - 50:
				continue
			_spikes.append({"off": off, "delay": i * ERUPT_STAGGER,
					"state": "waiting", "age": 0.0, "break_age": 0.0})


func update(dt: float) -> void:
	_timer += dt
	queue_redraw()
	if _timer < TELEGRAPH:
		return

	var t := _timer - TELEGRAPH
	var all_done := true
	for s in _spikes:
		match s.state:
			"waiting":
				all_done = false
				if t >= s.delay:
					s.state = "up"
					s.age = 0.0
					_erupt(s)
			"up":
				all_done = false
				s.age += dt
				if s.age >= STAND_TIME:
					_break(s, false)
				else:
					_touch(s)
			"breaking":
				s.break_age += dt
				if s.break_age < BREAK_TIME:
					all_done = false

	if all_done:
		dead = true
		queue_free()


# damage everything the spike pops up underneath
func _erupt(s: Dictionary) -> void:
	var wp: Vector2 = position + s.off
	game.spawn_burst(wp, GREEN, 7)

	var pl: Node2D = game.player
	if pl != null and pl.position.distance_to(wp) < ERUPT_RADIUS + pl.radius:
		pl.hit()

	for fp in game.alive_fake_players():
		if fp.position.distance_to(wp) < ERUPT_RADIUS + fp.radius:
			fp.hit()

	for c in game.alive_critters():
		if c.position.distance_to(wp) < ERUPT_RADIUS + c.radius:
			game.spawn_critter_squish(c.position)
			c.die()

	for sn in game.alive_snakes():
		if sn.hit_head(wp, ERUPT_RADIUS):
			sn.explode_head()
			continue
		var i: int = sn.hit_body(wp, ERUPT_RADIUS)
		if i >= 0:
			sn.cut_at(i)


# standing spikes hurt on touch; a dash shatters them instead
func _touch(s: Dictionary) -> void:
	if s.age < RISE_TIME:
		return  # eruption check already covered this moment
	var pl: Node2D = game.player
	if pl == null:
		return
	var wp: Vector2 = position + s.off
	if pl.position.distance_to(wp) >= HURT_RADIUS + pl.radius:
		return
	if pl.dash_time > 0:
		_break(s, true)
	else:
		pl.hit()


func _break(s: Dictionary, by_dash: bool) -> void:
	s.state = "breaking"
	s.break_age = 0.0
	var wp: Vector2 = position + s.off
	game.spawn_burst(wp, GREEN, 10 if by_dash else 5)
	if by_dash:
		game.add_score(10)
		game.spawn_hit_spark(wp, 36.0)


func _draw() -> void:
	if _timer < TELEGRAPH:
		_draw_telegraph()
		return

	# painter's order: lower spikes draw over higher ones for the perspective
	var order := range(_spikes.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return _spikes[a].off.y < _spikes[b].off.y)

	for idx in order:
		var s: Dictionary = _spikes[idx]
		var off: Vector2 = s.off
		match s.state:
			"waiting":
				# the ground bulges right before the spike pops
				Util.draw_shadow(self, off, 30.0, 0.9)
			"up":
				var age: float = s.age
				# flicker before retracting
				if STAND_TIME - age < 0.6 and int(floor(age * 10)) % 2 == 0:
					continue
				var k := clampf(age / RISE_TIME, 0.0, 1.0)
				var pop := 1.0 + maxf(0.0, 0.22 - age * 1.3)
				var size := DRAW_SIZE * k * pop
				# texture base sits on its bottom edge; keep it planted at off,
				# legs sinking a few px into the ground
				Util.draw_sprite(self, TEX_SPIKE, off + Vector2(0, -size * 0.5 + 8), size)
			"breaking":
				var alpha: float = 1.0 - s.break_age / BREAK_TIME
				Util.draw_sprite(self, TEX_BROKEN, off + Vector2(0, -26),
						64.0, Color(1, 1, 1, alpha))


func _draw_telegraph() -> void:
	var t := clampf(_timer / TELEGRAPH, 0.0, 1.0)
	var pulse := 0.7 + 0.3 * sin(_timer * 14.0)

	# faint marks along the whole path so the row is dodgeable
	for s in _spikes:
		Util.draw_shadow(self, s.off, 24.0, 0.25 + 0.55 * t)

	# bouncing exclamation mark at the spawn point
	var bob := absf(sin(_timer * 6.0)) * 8.0
	Util.draw_sprite(self, TEX_WARN, Vector2(0, -34 - bob), 52.0,
			Color(1, 1, 1, pulse))

	# an arrow per direction, nudging outward
	for d in _dirs:
		var apos: Vector2 = d * (58.0 + 8.0 * sin(_timer * 10.0))
		draw_set_transform(apos, d.angle(), Vector2.ONE)
		draw_texture_rect(TEX_ARROW, Rect2(Vector2(-22, -22), Vector2(44, 44)),
				false, Color(1, 1, 1, pulse))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
