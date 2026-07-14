class_name FakePlayer
extends Node2D
## Bot apple that wanders the arena so it feels like fake multiplayer.
## Snakes hunt these the same as the real player. They respawn after dying.

const NAMES := ["Mochi", "Crisp", "Pippin", "Tart", "Bramley", "Russet", "Honey"]
const TINTS := [
	Color(1.0, 0.82, 0.82),
	Color(0.82, 0.9, 1.0),
	Color(0.88, 1.0, 0.82),
	Color(1.0, 0.9, 0.72),
	Color(0.92, 0.82, 1.0),
]

var game: Node
var dead := false
var display_name := "Bot"
var tint := Color.WHITE

var vel := Vector2.ZERO
var radius := 28.0
var roll := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var invuln := 0.0
var respawn_in := 0.0

var _aim := Vector2.RIGHT
var _think_in := 0.0
var _tex: Texture2D = preload("res://assets/player.png")
var _tex_arrow: Texture2D = preload("res://assets/player_arrow_blue.png")


func setup(g: Node, pos: Vector2, bot_name: String, bot_tint: Color) -> void:
	game = g
	position = pos
	display_name = bot_name
	tint = bot_tint
	_aim = Vector2.from_angle(randf() * TAU)
	_think_in = randf()


func update(dt: float) -> void:
	if dead:
		respawn_in -= dt
		if respawn_in <= 0:
			_respawn()
		queue_redraw()
		return

	_think_in -= dt
	if _think_in <= 0:
		_think_in = randf_range(0.25, 0.55)
		_rethink()

	vel += _aim * 1300.0 * dt
	var damp := exp(-4.2 * dt)
	if is_zero_approx(_aim.x):
		vel.x *= damp
	if is_zero_approx(_aim.y):
		vel.y *= damp

	var max_sp := 780.0 if dash_time > 0 else 230.0
	if vel.length() > max_sp:
		vel = vel.normalized() * max_sp

	position += vel * dt
	position = position.clamp(
		Vector2(radius, radius),
		Vector2(game.WORLD_W - radius, game.WORLD_H - radius)
	)
	roll += (vel.x + vel.y) * dt / 26.0

	invuln = maxf(0, invuln - dt)
	dash_time = maxf(0, dash_time - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)

	for p in game.alive_pellets():
		if p.position.distance_to(position) < radius + p.radius:
			p.dead = true
			p.queue_free()
			game.spawn_burst(p.position, tint, 3)

	queue_redraw()


func _rethink() -> void:
	var nearest_snake: SnakeEnemy = null
	var nearest_d := INF
	for s in game.alive_snakes():
		var d: float = position.distance_to(s.head)
		if d < nearest_d:
			nearest_d = d
			nearest_snake = s

	if nearest_snake != null:
		var away: Vector2 = position - nearest_snake.head
		# panic dash away when cornered
		if nearest_d < 115.0 and away.length() > 0.001:
			_aim = away.normalized()
			if dash_cooldown <= 0:
				_dash()
			return
		# dash attack into nearby snakes
		if nearest_d < 250.0 and dash_cooldown <= 0 and randf() < 0.55:
			_aim = (nearest_snake.head - position).normalized()
			_dash()
			return

	# pellets are tasty bait
	var pellet: Node2D = null
	var pd := INF
	for p in game.alive_pellets():
		var d: float = p.position.distance_to(position)
		if d < pd:
			pd = d
			pellet = p
	if pellet != null and pd < 320.0:
		_aim = (pellet.position - position).normalized()
		return

	_aim = Vector2.from_angle(randf() * TAU)


func _dash() -> void:
	if _aim == Vector2.ZERO:
		_aim = Vector2.RIGHT
	vel = _aim * 680.0
	dash_time = 0.38
	dash_cooldown = randf_range(0.9, 1.8)
	game.spawn_burst(position, tint, 8)


func hit() -> void:
	if invuln > 0 or dead:
		return
	invuln = 1.5
	dead = true
	respawn_in = randf_range(3.0, 6.0)
	game.spawn_burst(position, tint, 14)
	game.spawn_hurt(position)
	hide()


func _respawn() -> void:
	dead = false
	invuln = 2.0
	vel = Vector2.ZERO
	position = Vector2(
		randf_range(180, game.WORLD_W - 180),
		randf_range(180, game.WORLD_H - 180)
	)
	show()


func resolve_circle(center: Vector2, cr: float) -> void:
	var d := position - center
	var dist := d.length()
	var min_d := radius + cr - 2.0
	if dist < min_d and dist > 0.001:
		var n := d / dist
		position += n * (min_d - dist)
		var dot := vel.dot(n)
		if dot < 0:
			vel -= n * dot * 1.1


func _draw() -> void:
	if dead:
		return
	if invuln > 0 and int(floor(invuln * 10)) % 2 == 0:
		return
	var bob := sin(Time.get_ticks_msec() / 320.0 + display_name.hash()) * 4.0
	Util.draw_shadow(self, Vector2.ZERO, 34)
	draw_set_transform(Vector2.ZERO, roll, Vector2.ONE)
	Util.draw_sprite(self, _tex, Vector2.ZERO, 34, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# small arrow so you can tell bots apart from your own marker
	Util.draw_sprite(self, _tex_arrow, Vector2(0, -48 + bob * 0.4), 28, tint)
