class_name SnakeEnemy
extends Node2D

const SEGMENT_SPACING := 22.0
const AVOID_RANGE := 150.0
const MIN_SPLIT_LEN := 4      # shorter halves cut normally
const MAX_SNAKES := 10
const SPLITTER_TINT := Color(1.25, 0.7, 1.3)

var game: Node
var kind := "normal"          # normal, armored, splitter, mace

var head := Vector2.ZERO
var angle := 0.0
var base_speed := 130.0
var turn_rate := 2.4
var head_radius := 20.0
var seg_radius := 14.0
var dead := false
var boost := 1.0
var retreat := 0.0            # backing off after a bite
var grace := 0.0              # no team kills right after splitting
var _turn_mul := 1.0          # mace snakes spin harder when attacking

# mace tail weapon (kind == "mace")
const MACE_ROPE := 84.0
const MACE_RADIUS := 17.0
const MACE_DRAW := 52.0
const MACE_MAX_SPEED := 950.0
var mace_pos := Vector2.ZERO
var mace_vel := Vector2.ZERO
var mace_rot := 0.0
var _mace_hit_cd := 0.0       # so one swing can't multi-hit the player
var _orbit_sign := 1.0        # which way we circle the player
var _orbit_swap := 2.5        # countdown to flipping the swing direction
var _mace_prev := Vector2.ZERO  # ball position last frame (verlet)

# past head positions, segments sit along this
var trail: Array[Vector2] = []
var segments: Array[Vector2] = []

var _tex: Texture2D = preload("res://assets/snake_body.png")
var _tex_armor: Texture2D = preload("res://assets/snake_armored.png")
var _tex_mace: Texture2D = preload("res://assets/mace_ball.png")

@onready var trail_painter := get_tree().current_scene.get_node("World/Background2/TrailPainter")


func setup(g: Node, pos: Vector2, length: int, speed: float, turn: float, ang: float) -> void:
	game = g
	head = pos
	base_speed = speed
	turn_rate = turn
	angle = ang
	trail = [pos]
	for i in length:
		segments.append(pos)


func update(dt: float) -> void:
	retreat = maxf(0, retreat - dt)
	grace = maxf(0, grace - dt)
	_mace_hit_cd = maxf(0, _mace_hit_cd - dt)
	if kind == "mace":
		_orbit_swap -= dt
		if _orbit_swap <= 0:
			_orbit_sign *= -1.0
			_orbit_swap = randf_range(1.6, 3.0)
	_turn_mul = 1.0
	var target := think()

	# steer toward target, away from other snakes and walls
	var dir := Vector2.from_angle((target - head).angle())

	for s in game.alive_snakes():
		if s == self:
			continue
		for seg: Vector2 in s.segments + [s.head]:
			var dd := head - seg
			var d := dd.length()
			if d < AVOID_RANGE and d > 0.001:
				dir += dd / d * ((1.0 - d / AVOID_RANGE) * 3.0)

	var m := 130.0
	if head.x < m:
		dir.x += (1 - head.x / m) * 2
	if head.x > game.WORLD_W - m:
		dir.x -= (1 - (game.WORLD_W - head.x) / m) * 2
	if head.y < m:
		dir.y += (1 - head.y / m) * 2
	if head.y > game.WORLD_H - m:
		dir.y -= (1 - (game.WORLD_H - head.y) / m) * 2

	var diff := wrapf(dir.angle() - angle, -PI, PI)
	var max_turn := turn_rate * _turn_mul * dt
	angle += clampf(diff, -max_turn, max_turn)

	head += Vector2.from_angle(angle) * (base_speed * boost * dt)
	head.x = clampf(head.x, -40, game.WORLD_W + 40)
	head.y = clampf(head.y, -40, game.WORLD_H + 40)

	trail.push_front(head)

	# place segments along the trail at fixed spacing
	var want := SEGMENT_SPACING
	var acc := 0.0
	var ti := 0
	for i in segments.size():
		while ti < trail.size() - 1:
			var a := trail[ti]
			var b := trail[ti + 1]
			var d := a.distance_to(b)
			if acc + d >= want:
				segments[i] = a.lerp(b, (want - acc) / d)
				break
			acc += d
			ti += 1
		want += SEGMENT_SPACING

	# drop trail we no longer need
	var max_len := (segments.size() + 2) * SEGMENT_SPACING
	var ln := 0.0
	for i in range(trail.size() - 1):
		ln += trail[i].distance_to(trail[i + 1])
		if ln > max_len:
			trail.resize(i + 2)
			break

	if kind == "mace":
		_update_mace(dt)

	# eat pellets near the head
	for p in game.alive_pellets():
		if p.position.distance_to(head) < head_radius + p.radius + 4:
			p.dead = true
			p.queue_free()
			grow(1)
			game.spawn_burst(p.position, Color("ffd32a"), 3)

	queue_redraw()


# pick a world-space point to steer toward
func think() -> Vector2:
	var d_player: float = game.player.position.distance_to(head)

	var pellet: Node2D = null
	var pd := INF
	for p in game.alive_pellets():
		var d: float = p.position.distance_to(head)
		if d < pd:
			pd = d
			pellet = p

	# nearest shorter snake is worth cutting off
	var victim: SnakeEnemy = null
	var vd := INF
	for s in game.alive_snakes():
		if s == self or s.segments.size() >= segments.size():
			continue
		var d: float = s.head.distance_to(head)
		if d < vd:
			vd = d
			victim = s

	boost = 1.0

	# back off after biting
	if retreat > 0:
		return head + (head - game.player.position)

	# mace snakes fight with the tail: circle the player to build swing
	# speed, and back off tail-first so the mace blocks incoming dashes
	if kind == "mace":
		_turn_mul = 1.8
		if game.player.dash_time > 0 and d_player < 320:
			return head + (head - game.player.position)
		if d_player < 480:
			boost = 1.25
			var to_p: Vector2 = game.player.position - head
			var tangent: Vector2 = to_p.orthogonal().normalized() * _orbit_sign
			# an orbit point past the player sweeps the tail across them
			return game.player.position - to_p.normalized() * 190.0 \
					+ tangent * 270.0
		return game.player.position

	# free food nearby beats everything
	if pellet != null and pd < 220 and pd < d_player * 0.8:
		return pellet.position

	# aim ahead of a smaller snake so our body crosses its path
	if victim != null and vd < 600 and segments.size() > 6:
		boost = 1.4
		var lead := minf(170, vd * 0.6)
		return victim.head + Vector2.from_angle(victim.angle) * lead

	# otherwise hunt the player
	if d_player < 280:
		boost = 1.3
	return game.player.position


func init_mace() -> void:
	mace_pos = _mace_anchor() + Vector2.from_angle(randf() * TAU) * MACE_ROPE
	_mace_prev = mace_pos


func _mace_anchor() -> Vector2:
	return segments[segments.size() - 1] if segments.size() > 0 else head


func mace_speed() -> float:
	return mace_vel.length()


# verlet ball on a rope: carry last frame's motion, then clamp to rope
# length. The constraint converts the tail's pull into a tangential whip
# on its own, which is what makes the flailing look right.
func _update_mace(dt: float) -> void:
	var anchor := _mace_anchor()
	var step := mace_pos - _mace_prev
	_mace_prev = mace_pos
	mace_pos += step * 0.985             # tiny drag so it settles when idle

	var d := mace_pos - anchor
	var dist := d.length()
	if dist > MACE_ROPE:
		mace_pos = anchor + d / dist * MACE_ROPE

	mace_vel = (mace_pos - _mace_prev) / maxf(dt, 0.0001)
	if mace_vel.length() > MACE_MAX_SPEED:
		mace_pos = _mace_prev + mace_vel.normalized() * MACE_MAX_SPEED * dt
		mace_vel = mace_vel.normalized() * MACE_MAX_SPEED

	mace_rot += mace_vel.length() * dt / 30.0

	# the ball crushes critters it plows through
	if mace_speed() > 90.0:
		for c in game.alive_critters():
			if c.position.distance_to(mace_pos) < MACE_RADIUS + c.radius:
				game.spawn_critter_squish(c.position)
				c.die()


func grow(n: int) -> void:
	for i in n:
		var tail := segments[segments.size() - 1] if segments.size() > 0 else head
		segments.append(tail)


# body only. returns the nearest overlapping segment, not the first by index,
# so a coiled snake can't turn a tail hit into a front-segment hit
func hit_body(p: Vector2, r: float) -> int:
	var neck_max := head_radius + seg_radius - 6
	var best := -1
	var best_d := INF
	for i in segments.size():
		var s := segments[i]
		if s.distance_to(head) < neck_max:
			continue
		var d := p.distance_to(s)
		if d < r + seg_radius and d < best_d:
			best_d = d
			best = i
	return best


func hit_head(p: Vector2, r: float) -> bool:
	return p.distance_to(head) < r + head_radius


func is_armored_at(index: int) -> bool:
	if kind == "mace":
		return true  # fully plated; only head hits work
	return kind == "armored" and index % 2 == 0


func cut_at(index: int) -> void:
	# splitter tails become a second snake instead of dying
	if kind == "splitter" and index >= MIN_SPLIT_LEN \
			and segments.size() - index >= MIN_SPLIT_LEN \
			and game.alive_snakes().size() < MAX_SNAKES:
		_split_at(index)
		return
	var removed: Array = segments.slice(index)
	segments.resize(index)
	for i in removed.size():
		var s: Vector2 = removed[i]
		game.spawn_burst(s, Color("2ed573"), 3)
		if i % 2 == 0:
			game.spawn_pellet(s)
	game.add_score(removed.size() * 10)
	if removed.size() >= 3 and randf() < 0.5:
		game.spawn_critter(removed[removed.size() - 1])
	if removed.size() > 0 and randf() < 0.35:
		# not at the impact point
		game.spawn_powerup(removed[floori(removed.size() / 2.0)])


func _split_at(index: int) -> void:
	var tail: Array[Vector2] = []
	tail.assign(segments.slice(index))
	segments.resize(index)
	game.add_score(10)
	game.spawn_burst(tail[0], Color("c56cf0"), 12)

	var s := SnakeEnemy.new()
	game.adopt_snake(s)
	s.setup(game, tail[0], 0, base_speed, turn_rate,
			(tail[0] - tail[1]).angle())
	s.kind = "splitter"
	s.head = tail[0]
	s.segments.assign(tail.slice(1))
	s.trail.assign(tail)
	s.retreat = 0.8
	s.grace = 1.2


# head explodes, first segment takes over. returns the old head position
func explode_head() -> Vector2:
	var old := head
	game.spawn_splat(old)
	game.spawn_burst(old, Color("ffd32a"), 24)
	game.add_score(50)
	game.spawn_critter(old)

	if segments.is_empty():
		die(null)
		game.add_score(100)
		return old

	head = segments.pop_front()
	if segments.size() > 0:
		angle = (head - segments[0]).angle()  # keep moving forward

	# trail must start at the new head or segments bunch up front
	var need := SEGMENT_SPACING
	var ti := 0
	while ti < trail.size() - 1 and need > 0:
		need -= trail[ti].distance_to(trail[ti + 1])
		ti += 1
	var trimmed: Array[Vector2] = []
	trimmed.assign(trail.slice(ti))
	trail = trimmed
	trail.push_front(head)

	retreat = 1.0
	return old


func die(killer: SnakeEnemy) -> void:
	if dead:
		return
	dead = true
	if killer != null:
		game.spawn_splat(head)
	game.spawn_burst(head, Color("2ed573"), 30)
	for i in range(0, segments.size(), 2):
		game.spawn_pellet(segments[i])
	for i in range(mini(2, segments.size())):
		game.spawn_critter(segments[i * (segments.size() - 1)])
	if killer != null:
		killer.grow(3)
	queue_free()

func paintTrail(pos) -> void:
	trail_painter.stamp(pos, 15)
	#print("Stamping at ", global_position)

func _draw() -> void:
	var mod := SPLITTER_TINT if kind == "splitter" else Color.WHITE
	Util.draw_shadow(self, head, 42)
	
	for s in segments:
		Util.draw_shadow(self, s, 34)

	# mace rope and ball go under the body
	if kind == "mace":
		var anchor := _mace_anchor()
		Util.draw_shadow(self, mace_pos, MACE_DRAW * 0.8)
		var links := 5
		for i in links:
			var t := (i + 1.0) / (links + 1.0)
			var p := anchor.lerp(mace_pos, t)
			draw_circle(p, 3.5, Color(0.13, 0.12, 0.11))
		draw_set_transform(mace_pos, mace_rot, Vector2.ONE)
		Util.draw_sprite(self, _tex_mace, Vector2.ZERO, MACE_DRAW)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for i in range(segments.size() - 1, -1, -1):
		var tex := _tex_armor if is_armored_at(i) else _tex
		Util.draw_sprite(self, tex, segments[i], 34, mod)
		paintTrail(segments[i])
	Util.draw_sprite(self, _tex, head, 42, mod)  # same orb, bigger
	paintTrail(head)
