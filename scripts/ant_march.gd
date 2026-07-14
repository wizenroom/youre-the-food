class_name AntMarch
extends Node2D
## A map-wide column of little ants marching across the arena for ~25s.
## One node simulates and draws the whole swarm procedurally: ants live in
## packed arrays, only the ones near the camera get drawn, so hundreds of
## them stay cheap. Touching the stream hurts; dashing through squishes.

const TELEGRAPH := 1.7
const LANES := 5
const LANE_SPACING := 26.0
const ANT_SPACING := 48.0
const SPEED := 210.0
const STREAM_LEN := 2600.0    # trail length; ~25-30s total with map crossing
const ANT_RADIUS := 10.0
const DRAW_SIZE := 34.0
# camera can see ~480px past the world edge when you hug the wall, so ants
# must walk this far off the map before despawning to vanish off-canvas
const EDGE_MARGIN := 560.0

const TEX_FRAMES: Array[Texture2D] = [
	preload("res://assets/ant_walk1.png"),
	preload("res://assets/ant_walk2.png"),
]
const TEX_WARN := preload("res://assets/spike_warn.png")
const TEX_ARROW := preload("res://assets/spike_arrow.png")
const TEX_SQUISH := preload("res://assets/ant_squish.png")

const BAND_TINT := Color(0.12, 0.11, 0.10)

var game: Node
var dead := false

var _timer := 0.0
var _dir := Vector2.RIGHT     # march direction (cardinal)
var _perp := Vector2.DOWN     # band-thickness axis
var _entry := Vector2.ZERO    # where the stream head enters, band center
var _map_len := 0.0

# one ant per index
var _along: PackedFloat32Array = []   # distance behind the stream head
var _off: PackedFloat32Array = []     # offset from the band center line
var _phase: PackedFloat32Array = []
var _squished: PackedByteArray = []


func setup(g: Node, horizontal: bool, positive: bool, band_coord: float) -> void:
	game = g
	if horizontal:
		_dir = Vector2.RIGHT if positive else Vector2.LEFT
		_perp = Vector2.DOWN
		_map_len = game.WORLD_W + EDGE_MARGIN * 2
		var x: float = -EDGE_MARGIN if positive else game.WORLD_W + EDGE_MARGIN
		_entry = Vector2(x, band_coord)
	else:
		_dir = Vector2.DOWN if positive else Vector2.UP
		_perp = Vector2.RIGHT
		_map_len = game.WORLD_H + EDGE_MARGIN * 2
		var y: float = -EDGE_MARGIN if positive else game.WORLD_H + EDGE_MARGIN
		_entry = Vector2(band_coord, y)

	var per_lane := int(STREAM_LEN / ANT_SPACING)
	for lane in LANES:
		var lane_off := (lane - (LANES - 1) * 0.5) * LANE_SPACING
		for k in per_lane:
			_along.append(k * ANT_SPACING + randf() * 26.0 - 13.0 \
					+ (lane % 2) * ANT_SPACING * 0.5)
			_off.append(lane_off + randf() * 14.0 - 7.0)
			_phase.append(randf() * TAU)
			_squished.append(0)


func update(dt: float) -> void:
	_timer += dt
	queue_redraw()
	if _timer < TELEGRAPH:
		return
	var t := _timer - TELEGRAPH
	var head := SPEED * t

	if head - STREAM_LEN > _map_len:
		dead = true
		queue_free()
		return

	var pl: Node2D = game.player
	if pl == null:
		return
	# the whole swarm shares one line, so bail early when the player is
	# nowhere near the band instead of testing every ant
	var band_half := (LANES - 1) * 0.5 * LANE_SPACING + 10.0
	var pdist := absf((pl.position - _entry).dot(_perp))
	if pdist > band_half + pl.radius + ANT_RADIUS:
		return

	for i in _along.size():
		if _squished[i]:
			continue
		var d := head - _along[i]
		if d < 0.0 or d > _map_len:
			continue
		var pos := _entry + _dir * d + _perp * _off[i]
		if pos.distance_to(pl.position) >= ANT_RADIUS + pl.radius:
			continue
		if pl.dash_time > 0:
			_squished[i] = 1
			game.add_score(2)
			game.spawn_squish(pos, TEX_SQUISH, 38.0)
			game.spawn_burst(pos, BAND_TINT, 4)
		else:
			pl.hit()


func _draw() -> void:
	if _timer < TELEGRAPH:
		_draw_telegraph()
		return

	var t := _timer - TELEGRAPH
	var head := SPEED * t

	# only draw what the camera can see
	var cam: Vector2 = game.camera.position
	var view := Rect2(cam - Vector2(520, 380), Vector2(1040, 760))

	var frame := 0
	for i in _along.size():
		if _squished[i]:
			continue
		var d := head - _along[i]
		if d < 0.0 or d > _map_len:
			continue
		var wob := sin(t * 10.0 + _phase[i])
		var pos := _entry + _dir * d + _perp * (_off[i] + wob * 2.5)
		if not view.has_point(pos):
			continue
		frame = int(t * 8.0 + _phase[i]) % 2
		var rot := _dir.angle() + wob * 0.12
		var scl := Vector2.ONE
		if _dir == Vector2.LEFT:
			rot = wob * 0.12   # flip instead of rotating upside down
			scl = Vector2(-1, 1)
		draw_set_transform(pos, rot, scl)
		draw_texture_rect(TEX_FRAMES[frame],
				Rect2(Vector2(-DRAW_SIZE, -DRAW_SIZE) / 2.0,
						Vector2(DRAW_SIZE, DRAW_SIZE)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_telegraph() -> void:
	var pulse := 0.55 + 0.45 * sin(_timer * 12.0)
	var band_half := (LANES - 1) * 0.5 * LANE_SPACING + 16.0

	# faint stripe across the whole map where the column will walk
	var a := _entry - _perp * band_half
	var b := _entry + _dir * _map_len - _perp * band_half
	var stripe := Rect2(a, Vector2.ZERO).expand(b + _perp * band_half * 2.0)
	draw_rect(stripe, Color(BAND_TINT.r, BAND_TINT.g, BAND_TINT.b,
			0.10 + 0.06 * pulse))

	# arrows marching along the stripe, warn marks in between
	var steps := int(_map_len / 360.0)
	for i in steps + 1:
		var p := _entry + _dir * (i * 360.0 + 100.0)
		draw_set_transform(p, _dir.angle(), Vector2.ONE)
		draw_texture_rect(TEX_ARROW, Rect2(Vector2(-24, -24), Vector2(48, 48)),
				false, Color(1, 1, 1, pulse))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if i % 2 == 0:
			Util.draw_sprite(self, TEX_WARN,
					p + _dir * 180.0 + Vector2(0, -band_half - 22), 46.0,
					Color(1, 1, 1, pulse))
