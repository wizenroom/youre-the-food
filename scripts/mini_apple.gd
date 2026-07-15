class_name MiniApple
extends Node2D
## Little apple buddy bought with points. Follows the player like a duckling,
## squishes critters underfoot, and when rallied it charges the nearest snake.
## Three flavors:
##  fighter - rally specialist, survives cutting an unarmored body
##  scout   - fast, wide pellet vacuum, pellets worth double
##  tank    - chunky bodyguard, survives two snake chomps and shoves heads back

const TINTS := {
	"fighter": Color(1.0, 0.62, 0.55),
	"scout": Color(0.72, 1.0, 0.62),
	"tank": Color(0.6, 0.8, 1.0),
}
const KINDS := ["fighter", "scout", "tank"]

var game: Node
var dead := false
var kind := "fighter"
var tint := Color.WHITE
var radius := 13.0
var hp := 1
var vel := Vector2.ZERO
var roll := 0.0
var invuln := 0.0
var rallying := false
var rally_left := 0.0
var _seed := 0.0
var _draw_size := 22.0
var _pellet_reach := 0.0
var _pellet_score := 5
var _tex: Texture2D = preload("res://assets/player.png")


func setup(g: Node, pos: Vector2, mini_kind: String = "") -> void:
	game = g
	position = pos
	kind = mini_kind if mini_kind in KINDS else KINDS[randi() % KINDS.size()]
	tint = TINTS[kind]
	_seed = randf() * TAU
	match kind:
		"scout":
			radius = 11.0
			_draw_size = 19.0
			_pellet_reach = 26.0
			_pellet_score = 10
		"tank":
			radius = 18.0
			_draw_size = 30.0
			hp = 2
	game.spawn_burst(pos, tint, 8)


func rally() -> void:
	if dead or rallying:
		return
	rallying = true
	rally_left = 3.2 if kind == "fighter" else 2.5
	game.spawn_burst(position, tint, 5)


func update(dt: float) -> void:
	if dead:
		return

	invuln = maxf(0, invuln - dt)

	var target := position
	var speed := 320.0
	var speed_mul := 1.35 if kind == "scout" else 1.0

	if rallying:
		rally_left -= dt
		var prey := _nearest_snake_head()
		if prey == Vector2.INF or rally_left <= 0:
			rallying = false
		else:
			target = prey
			speed = (780.0 if kind == "fighter" else 700.0)

	if not rallying and game.player != null:
		# trail behind the player at a personal angle so they fan out
		var ring := Vector2.from_angle(_seed + Time.get_ticks_msec() / 2400.0) * 74.0
		target = game.player.position + ring
		speed = (460.0 if position.distance_to(target) > 220.0 else 320.0) * speed_mul

	var to_t := target - position
	if to_t.length() > 8.0:
		vel += to_t.normalized() * 2100.0 * dt
	vel *= exp(-4.6 * dt)
	if vel.length() > speed:
		vel = vel.normalized() * speed

	# personal space between the little guys
	for m in game.alive_minis():
		if m == self:
			continue
		var d: Vector2 = position - m.position
		var dist := d.length()
		var gap: float = radius + m.radius
		if dist < gap and dist > 0.001:
			position += d / dist * (gap - dist) * 0.5

	position += vel * dt
	position = position.clamp(
		Vector2(radius, radius),
		Vector2(game.WORLD_W - radius, game.WORLD_H - radius)
	)
	roll += (vel.x + vel.y) * dt / 14.0

	# tiny helpers nibble pellets for you
	for p in game.alive_pellets():
		if p.position.distance_to(position) < radius + p.radius + _pellet_reach:
			p.dead = true
			p.queue_free()
			game.add_score(_pellet_score)
			game.spawn_burst(p.position, tint, 3)

	queue_redraw()


func _nearest_snake_head() -> Vector2:
	var best := Vector2.INF
	var best_d := 900.0
	for s in game.alive_snakes():
		var d: float = position.distance_to(s.head)
		if d < best_d:
			best_d = d
			best = s.head
	return best


## a snake head bit this mini; returns true if it survived
func take_chomp() -> bool:
	if invuln > 0:
		return true
	hp -= 1
	if hp <= 0:
		die()
		return false
	invuln = 0.8
	game.spawn_burst(position, tint, 6)
	return true


func die() -> void:
	if dead:
		return
	dead = true
	game.spawn_burst(position, tint, 10)
	hide()
	queue_free()


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
	if invuln > 0 and int(floor(invuln * 12)) % 2 == 0:
		return
	var bob := sin(Time.get_ticks_msec() / 240.0 + _seed) * 2.5
	Util.draw_shadow(self, Vector2.ZERO, _draw_size * 0.8)
	draw_set_transform(Vector2(0, bob), roll, Vector2.ONE)
	Util.draw_sprite(self, _tex, Vector2.ZERO, _draw_size, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if rallying:
		draw_circle(Vector2(0, -_draw_size * 0.8 + bob), 3.0, Color(1, 0.35, 0.3))
