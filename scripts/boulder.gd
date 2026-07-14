class_name BoulderStrike
extends Node2D

const TELEGRAPH := 1.15      # warning time before impact
const FALL_TIME := 0.22      # last stretch where the falling rock is visible
const IMPACT_RADIUS := 52.0
const REST_TIME := 3.5
const CRUMBLE_TIME := 1.4

const STONE_DARK := Color(0.30, 0.29, 0.27)

enum Phase { TELEGRAPH, RESTING, CRUMBLING }

var game: Node
var dead := false
var rock_radius := 26.0 + randf() * 8.0

var _phase := Phase.TELEGRAPH
var _timer := 0.0
var _crumble_rot := (randf() - 0.5) * 0.9  # so repeats don't look stamped

var _tex_indicator: Texture2D = preload("res://assets/boulder_indicator.png")
var _tex_rock: Texture2D = preload("res://assets/rock.png")
var _tex_crumble: Texture2D = preload("res://assets/rock_crumble.png")


func setup(g: Node) -> void:
	game = g


func update(dt: float) -> void:
	_timer += dt

	match _phase:
		Phase.TELEGRAPH:
			if _timer >= TELEGRAPH:
				_impact()
		Phase.RESTING:
			# resting rock is solid
			if game.player != null:
				game.player.resolve_circle(position, rock_radius)
			if _timer >= REST_TIME:
				_phase = Phase.CRUMBLING
				_timer = 0.0
				game.spawn_burst(position, STONE_DARK, 14)
		Phase.CRUMBLING:
			if _timer >= CRUMBLE_TIME:
				dead = true
				queue_free()

	queue_redraw()


func _impact() -> void:
	_phase = Phase.RESTING
	_timer = 0.0
	game.spawn_burst(position, STONE_DARK, 18)

	var pl: Node2D = game.player
	if pl != null and pl.position.distance_to(position) < IMPACT_RADIUS + pl.radius:
		pl.hit()

	for c in game.alive_critters():
		if c.position.distance_to(position) < IMPACT_RADIUS + c.radius:
			game.spawn_critter_squish(c.position)
			c.die()

	# heads explode, bodies get severed
	for s in game.alive_snakes():
		if s.hit_head(position, IMPACT_RADIUS):
			s.explode_head()
			continue
		var i: int = s.hit_body(position, IMPACT_RADIUS)
		if i >= 0:
			s.cut_at(i)


func _draw() -> void:
	match _phase:
		Phase.TELEGRAPH:
			# indicator grows and pulses as the drop closes in
			var t := clampf(_timer / TELEGRAPH, 0.0, 1.0)
			Util.draw_shadow(self, Vector2.ZERO, 30.0 + t * 60.0, 0.4 + t * 0.6)
			var pulse := 0.75 + 0.25 * sin(_timer * 14.0)
			var ind_size := IMPACT_RADIUS * 2.2 * (0.55 + t * 0.45)
			Util.draw_sprite(self, _tex_indicator, Vector2.ZERO, ind_size,
					Color(1, 1, 1, pulse))
			# rock streaks in from above at the end
			var fall_t := (TELEGRAPH - _timer) / FALL_TIME
			if fall_t < 1.0:
				_draw_rock(Vector2(0, -fall_t * 420.0), 1.0)

		Phase.RESTING:
			# squash pop on arrival, flicker before crumbling
			var age := _timer
			if REST_TIME - age < 0.8 and int(floor(age * 10)) % 2 == 0:
				return
			var pop := 1.0 + maxf(0.0, 0.25 - age * 1.4)
			Util.draw_shadow(self, Vector2(0, rock_radius * 0.3), rock_radius * 2.4)
			_draw_rock(Vector2.ZERO, pop)

		Phase.CRUMBLING:
			var pop := minf(1.0, _timer * 8.0)
			var alpha := 1.0 - _timer / CRUMBLE_TIME
			draw_set_transform(Vector2.ZERO, _crumble_rot, Vector2.ONE)
			Util.draw_sprite(self, _tex_crumble, Vector2.ZERO,
					rock_radius * 3.0 * pop, Color(1, 1, 1, alpha))


func _draw_rock(at: Vector2, scale_f: float) -> void:
	Util.draw_sprite(self, _tex_rock, at, rock_radius * 2.4 * scale_f)
