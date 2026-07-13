extends Node2D

enum State { MENU, OPTIONS, PLAYING, PAUSED, GAMEOVER }

const WORLD_W := 2880.0
const WORLD_H := 1920.0
const VIEW_W := 960.0
const VIEW_H := 640.0

const TEX_ON := preload("res://assets/ui_on.png")
const TEX_OFF := preload("res://assets/ui_off.png")
const TEX_BLOCK := preload("res://assets/fx_block.png")
const SAVE_PATH := "user://highscore.cfg"
const BOULDER := preload("res://scripts/boulder.gd")
const CRITTER := preload("res://scripts/critter.gd")
const MAX_CRITTERS := 12

var state: State = State.MENU
var score := 0
var wave := 0
var wave_banner := 0.0
var wave_duration := 30.0    
var wave_timer := 30.0
var shadows_enabled := true
var grid_enabled := true
var player: FoodPlayer = null
var aim := Vector2.ZERO      
var boulder_timer := 0.0     # countdown to the next rock drop
var high_score := 0
var high_wave := 0

@onready var camera: Camera2D = $Camera
@onready var hud: Control = $UI/HUD


func _ready() -> void:
	randomize()
	$UI/Menu/PlayButton.pressed.connect(start)
	$UI/Menu/OptionsButton.pressed.connect(func() -> void: set_state(State.OPTIONS))
	$UI/OptionsMenu/ShadowsButton.pressed.connect(_toggle_shadows)
	$UI/OptionsMenu/GridButton.pressed.connect(_toggle_grid)
	$UI/OptionsMenu/BackButton.pressed.connect(func() -> void: set_state(State.MENU))
	$UI/PauseMenu/RestartButton.pressed.connect(start)
	$UI/PauseMenu/BackButton.pressed.connect(to_menu)
	$UI/DeathScreen/RestartButton.pressed.connect(start)
	$UI/DeathScreen/BackButton.pressed.connect(to_menu)
	_load_high_score()
	set_state(State.MENU)


func set_state(s: State) -> void:
	state = s
	$UI/Menu.visible = s == State.MENU
	$UI/OptionsMenu.visible = s == State.OPTIONS
	$UI/PauseMenu.visible = s == State.PAUSED
	$UI/DeathScreen.visible = s == State.GAMEOVER
	hud.visible = s != State.MENU and s != State.OPTIONS
	if s == State.MENU or s == State.OPTIONS:
		camera.position = Vector2(VIEW_W / 2, VIEW_H / 2)
		camera.reset_smoothing()


func start() -> void:
	_clear_world()
	player = FoodPlayer.new()
	$World/PlayerRoot.add_child(player)
	player.setup(self, Vector2(WORLD_W / 2, WORLD_H / 2))
	score = 0
	wave = 0
	set_state(State.PLAYING)
	camera.position = player.position
	camera.reset_smoothing()
	next_wave()


func to_menu() -> void:
	_clear_world()
	set_state(State.MENU)


func _clear_world() -> void:
	for group in [$World/Snakes, $World/Pellets, $World/Powerups, $World/Splats, $World/Hazards, $World/Critters, $World/PlayerRoot]:
		for c in group.get_children():
			if "dead" in c:
				c.dead = true
			c.hide()
			c.queue_free()
	$World/Effects.clear()
	player = null


func next_wave() -> void:
	wave += 1
	wave_banner = 2.0
	wave_timer = wave_duration
	boulder_timer = 3.0
	var count := mini(1 + wave, 5)
	var spawned: Array[SnakeEnemy] = []
	for i in count:
		spawned.append(spawn_snake())
	# from wave 2 on, never roll an all-normal wave
	if wave >= 2:
		var has_variant := false
		for s in spawned:
			if s.kind != "normal":
				has_variant = true
				break
		if not has_variant:
			var pick: SnakeEnemy = spawned[randi() % spawned.size()]
			_make_variant(pick, "splitter" if randf() < 0.5 else "armored")


func spawn_snake() -> SnakeEnemy:
	# random edge, aimed at the middle
	var edge := randi() % 4
	var pos: Vector2
	match edge:
		0: pos = Vector2(80, randf() * WORLD_H)
		1: pos = Vector2(WORLD_W - 80, randf() * WORLD_H)
		2: pos = Vector2(randf() * WORLD_W, 80)
		_: pos = Vector2(randf() * WORLD_W, WORLD_H - 80)

	var s := SnakeEnemy.new()
	$World/Snakes.add_child(s)
	s.setup(
		self, pos,
		6 + wave * 2,
		minf(130 + wave * 10, 260),
		minf(2.4 + wave * 0.1, 3.8),
		(Vector2(WORLD_W / 2, WORLD_H / 2) - pos).angle()
	)
	# variants show up from wave 2, ramping up fast
	if wave >= 2 and randf() < minf(0.15 + wave * 0.05, 0.45):
		_make_variant(s, "splitter")
	elif wave >= 2 and randf() < minf(0.20 + wave * 0.05, 0.50):
		_make_variant(s, "armored")
	return s


func _make_variant(s: SnakeEnemy, k: String) -> void:
	s.kind = k
	if k == "armored":
		s.base_speed *= 0.85


func adopt_snake(s: SnakeEnemy) -> void:
	$World/Snakes.add_child(s)


# boulders rain from wave 2 on
func _update_boulders(dt: float) -> void:
	if wave < 2:
		return
	boulder_timer -= dt
	if boulder_timer > 0:
		return
	boulder_timer = maxf(4.5 - wave * 0.35, 1.6) * (0.75 + randf() * 0.5)

	# lead the player a bit, then scatter — close but dodgeable
	var target: Vector2 = player.position + player.vel * 0.6
	target += Vector2.from_angle(randf() * TAU) * (60.0 + randf() * 260.0)
	target.x = clampf(target.x, 60, WORLD_W - 60)
	target.y = clampf(target.y, 60, WORLD_H - 60)

	var b := BOULDER.new()
	b.position = target
	$World/Hazards.add_child(b)
	b.setup(self)


func alive_snakes() -> Array:
	var out := []
	for s in $World/Snakes.get_children():
		if not s.dead:
			out.append(s)
	return out


func alive_critters() -> Array:
	var out := []
	for c in $World/Critters.get_children():
		if not c.dead:
			out.append(c)
	return out


func alive_pellets() -> Array:
	var out := []
	for p in $World/Pellets.get_children():
		if not p.dead:
			out.append(p)
	return out


func alive_powerups() -> Array:
	var out := []
	for p in $World/Powerups.get_children():
		if not p.dead:
			out.append(p)
	return out


func add_score(n: int) -> void:
	score += n


func spawn_burst(pos: Vector2, color: Color, count: int) -> void:
	$World/Effects.burst(pos, color, count)


func spawn_pellet(pos: Vector2) -> void:
	if alive_pellets().size() >= 150:
		return
	var p := PelletFood.new()
	p.position = pos + Vector2((randf() - 0.5) * 18, (randf() - 0.5) * 18)
	$World/Pellets.add_child(p)


func spawn_powerup(pos: Vector2) -> void:
	var p := PowerUpPickup.new()
	p.position = pos
	$World/Powerups.add_child(p)


func spawn_critter(pos: Vector2) -> void:
	if alive_critters().size() >= MAX_CRITTERS:
		return
	var c := CRITTER.new()
	$World/Critters.add_child(c)
	c.setup(
		self,
		pos + Vector2((randf() - 0.5) * 30, (randf() - 0.5) * 30),
		minf(100 + wave * 5, 190)
	)


func spawn_splat(pos: Vector2) -> void:
	var s := SplatStain.new()
	s.position = pos
	$World/Splats.add_child(s)


func game_over() -> void:
	$UI/DeathScreen/ScoreValue.text = str(score)
	$UI/DeathScreen/WaveValue.text = str(wave)
	var beat_record := score > high_score
	if beat_record:
		high_score = score
		high_wave = wave
		_save_high_score()
		_refresh_high_score_label()
	$UI/DeathScreen/NewBest.visible = beat_record
	set_state(State.GAMEOVER)


func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = cfg.get_value("best", "score", 0)
		high_wave = cfg.get_value("best", "wave", 0)
	_refresh_high_score_label()


func _save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("best", "score", high_score)
	cfg.set_value("best", "wave", high_wave)
	cfg.save(SAVE_PATH)


func _refresh_high_score_label() -> void:
	$UI/Menu/HighScoreValue.text = str(high_score)
	$UI/Menu/HighScoreValue.visible = high_score > 0
	$UI/Menu/HighScoreLabel.visible = high_score > 0


func _toggle_shadows() -> void:
	shadows_enabled = not shadows_enabled
	Util.shadows_enabled = shadows_enabled
	$UI/OptionsMenu/StateIcon.texture = TEX_ON if shadows_enabled else TEX_OFF


func _toggle_grid() -> void:
	grid_enabled = not grid_enabled
	$World/Grid.visible = grid_enabled
	$UI/OptionsMenu/GridStateIcon.texture = TEX_ON if grid_enabled else TEX_OFF


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0)
	match state:
		State.MENU:
			if Input.is_action_just_pressed("menu_start"):
				start()
		State.OPTIONS:
			if Input.is_action_just_pressed("pause_toggle"):
				set_state(State.MENU)
		State.PAUSED:
			if Input.is_action_just_pressed("pause_toggle"):
				set_state(State.PLAYING)
			hud.update_hud()
		State.GAMEOVER:
			if Input.is_action_just_pressed("restart_key"):
				start()
			hud.update_hud()
		State.PLAYING:
			if Input.is_action_just_pressed("pause_toggle"):
				set_state(State.PAUSED)
				return
			_update_game(dt)
			if state != State.MENU:  # game_over may have fired mid-update
				hud.update_hud()


func _update_game(dt: float) -> void:
	wave_banner = maxf(0, wave_banner - dt)
	aim = get_global_mouse_position()

	player.update(dt)
	for s in alive_snakes():
		s.update(dt)
	for c in alive_critters():
		c.update(dt)
	for p in $World/Powerups.get_children():
		p.update(dt)
	for sp in $World/Splats.get_children():
		sp.update(dt)
	_update_boulders(dt)
	for b in $World/Hazards.get_children():
		if not b.dead:
			b.update(dt)
	$World/Effects.update(dt)

	camera.position = player.position

	# --- collisions ---

	var dash_hit := false

	# dash attacks. hits near the head count as head hits, otherwise the
	# neck shields it forever and cutting there wipes the whole body
	if player.is_dashing:
		for s in alive_snakes():
			var head_hit: bool = s.hit_head(player.position, player.radius + 6)
			var body_hit: int = s.hit_body(player.position, player.radius)

			# armor blocks the dash, even pierce
			if body_hit >= 0 and s.is_armored_at(body_hit) and not head_hit:
				$World/Effects.popup(player.position + Vector2(0, -30), TEX_BLOCK)
				player.vel *= -0.55
				player.dash_time = 0
				player.invuln = maxf(player.invuln, 0.4)
				player.hittedSomethingWhileDashing()
				dash_hit = true  # no bite on the same touch
				break

			if head_hit or (body_hit >= 0 and body_hit <= 2):
				var boom: Vector2 = s.explode_head()
				# shove clear so the damage check can't re-trigger
				var d := player.position - boom
				var dist := maxf(d.length(), 1.0)
				player.position += d / dist * 40.0
				player.invuln = maxf(player.invuln, 0.5)
				dash_hit = true
				player.hittedSomethingWhileDashing()
				if player.power != "pierce":
					player.vel *= -0.35
					player.dash_time = 0
				break

			if body_hit >= 0:
				s.cut_at(body_hit)
				spawn_burst(player.position, Color("2ed573"), 12)
				player.invuln = maxf(player.invuln, 0.3)
				dash_hit = true
				player.hittedSomethingWhileDashing()
				if player.power != "pierce":
					player.vel *= -0.4
					player.dash_time = 0
				break

	# push out of bodies (neck counts as head)
	for s in alive_snakes():
		var neck_max: float = s.head_radius + s.seg_radius - 6
		for seg: Vector2 in s.segments:
			if seg.distance_to(s.head) < neck_max:
				continue
			player.resolve_circle(seg, s.seg_radius)
		player.resolve_circle(s.head, s.head_radius)

	# head and body both hurt, unless the dash just connected
	if not dash_hit:
		for s in alive_snakes():
			var body_hit: int = s.hit_body(player.position, player.radius)
			var head_hit: bool = s.hit_head(player.position, player.radius)
			if body_hit >= 0 or head_hit:
				player.hit()
				if head_hit:
					s.retreat = 1.2
				break

	# team kill: head into another snake's body = dead
	for a in alive_snakes():
		if a.dead or a.grace > 0:
			continue
		for b in alive_snakes():
			if b == a or b.dead:
				continue
			var crashed := false
			for seg: Vector2 in b.segments:
				if a.head.distance_to(seg) < a.head_radius + b.seg_radius - 6:
					crashed = true
					break
			if crashed:
				a.die(b)
				add_score(100)
				break

	# critters die on contact either way, so invuln can't farm them
	for c in alive_critters():
		if c.position.distance_to(player.position) < c.radius + player.radius:
			if player.dash_time > 0:
				add_score(15)
				c.die()
			elif c.awake():
				player.hit()
				c.die()

	for p in alive_powerups():
		if p.position.distance_to(player.position) < p.radius + player.radius:
			p.dead = true
			p.queue_free()
			player.pick_up(p.kind)
			spawn_burst(p.position, Color("ffd32a"), 10)

	for p in alive_pellets():
		if p.position.distance_to(player.position) < p.radius + player.radius:
			p.dead = true
			p.queue_free()
			add_score(5)

	# clear the wave early or the timer piles the next one on top
	wave_timer -= dt
	if alive_snakes().is_empty() or wave_timer <= 0:
		next_wave()
