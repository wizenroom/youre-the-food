class_name FoodPlayer
extends Node2D


@onready var vignette: ColorRect = get_tree().current_scene.get_node("CanvasLayer/ColorRect")
@onready var vignette_mat: ShaderMaterial = vignette.material as ShaderMaterial
var vignette_color: Color = Color.BLACK

#@onready var trail_painter := get_tree().current_scene.get_node("World/Background2/TrailPainter")

var game: Node

var vel := Vector2.ZERO
var radius := 30.0
var accel := 1600.0
var max_speed := 280.0
var friction := 4.5
var roll := 0.0
var max_lives := 3
var lives := 3
var invuln := 0.0
var hurt_flash := 0.0        # visual-only: set when a life is lost, not on dash invuln
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_cd_total := 0.85
var power := ""              # "", "turbo", "shield" or "pierce"
var power_time := 0.0

var is_dashing = false
const DASH_PARTICLE_EVERY = 0.025
var _shouldproduceddashparticle = false
var _lastdashcount = 0

var successfulhit = false

var damaged = false

var _tex: Texture2D = preload("res://assets/player.png")
var _tex_streak: Texture2D = preload("res://assets/fx_speed_streak.png")
var _tex_shield: Texture2D = preload("res://assets/powerup_shield.png")
var _tex_pierce: Texture2D = preload("res://assets/powerup_pierce.png")
# the painted lightning points up-right at roughly this angle
const STREAK_ART_ANGLE := 0.45


func setup(g: Node, pos: Vector2) -> void:
	game = g
	position = pos


func update(dt: float) -> void:
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	vel += axis * accel * dt

	# friction only brakes axes you aren't pushing, so you drift
	var damp := exp(-friction * dt)
	if is_zero_approx(axis.x):
		vel.x *= damp
	if is_zero_approx(axis.y):
		vel.y *= damp

	var max_sp: float = 850.0 if dash_time > 0 else max_speed
	if vel.length() > max_sp:
		vel = vel.normalized() * max_sp

	position += vel * dt
	if position.x < radius or position.x > game.WORLD_W - radius:
		vel.x = 0
	if position.y < radius or position.y > game.WORLD_H - radius:
		vel.y = 0
	position = position.clamp(
		Vector2(radius, radius),
		Vector2(game.WORLD_W - radius, game.WORLD_H - radius)
	)

	roll += (vel.x + vel.y) * dt / 24.0

	invuln = maxf(0, invuln - dt)
	hurt_flash = maxf(0, hurt_flash - dt)
	dash_time = maxf(0, dash_time - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)

	if power != "":
		power_time -= dt
		if power_time <= 0:
			power = ""

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
		dash()
		
		
	updateDashVar()
	tryProduceDashParticle()
	updateSuccessfulhit()
	queue_redraw()
	updateDamaged()
	updateVignette(0.003)
	#paintPlayerTrail()

#func paintPlayerTrail() -> void:
	#trail_painter.stamp(global_position, 1)
	#print("Stamping at ", global_position)

func updateVignette(delta: float) -> void:
	var target := Color.BLACK

	if successfulhit:
		target = Color(0.228, 0.551, 0.316, 1.0)
	elif damaged:
		target = Color.RED

	vignette_color = vignette_color.lerp(target, delta * 5.0)

	vignette_mat.set_shader_parameter("vignette_color", vignette_color)


func updateDamaged() -> void:
	if invuln <= 0:
		damaged = false

func updateSuccessfulhit() -> void:
	if invuln <= 0:
		successfulhit = false

func updateLastDashCount() -> void:
	_lastdashcount = floorf(dash_time / DASH_PARTICLE_EVERY)
	

func tryProduceDashParticle() -> void:
	if is_dashing != true:
		return
	
	var currentcount = floorf(dash_time / DASH_PARTICLE_EVERY)
	if _lastdashcount != currentcount:
		_lastdashcount = currentcount
		game.spawn_burst(position, Color("ff4757"), 1)
	

func updateDashVar() -> void:
	if dash_time > 0:
			is_dashing = true
	else:
			is_dashing = false

# dash toward the cursor; while active, ramming a snake severs it
func dash() -> void:
	var dir: Vector2 = (game.aim - position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	vel = dir * 720.0
	dash_time = 0.4
	dash_cd_total = 0.35 if power == "turbo" else 0.85
	dash_cooldown = dash_cd_total
	game.spawn_burst(position, Color("ff4757"), 8)
	
	updateLastDashCount()
	
	

func hittedSomethingWhileDashing() -> void:
	successfulhit = true
	
func hit() -> void:
	if invuln > 0:
		return
	
	
	
	if power == "shield":
		power = ""
		invuln = 1.2
		game.spawn_burst(position, Color("7bed9f"), 14)
		return
	lives -= 1
	invuln = 2.0
	hurt_flash = 2.0
	
	damaged = true
	
	game.spawn_hurt(position)
	if lives <= 0:
		game.game_over()


# push out of a solid circle without damage
func resolve_circle(center: Vector2, cr: float) -> void:
	var d := position - center
	var dist := d.length()
	var min_d := radius + cr - 2.0
	if dist < min_d and dist > 0.001:
		var n := d / dist
		position += n * (min_d - dist)
		# bleed some velocity so you slide along bodies
		var dot := vel.dot(n)
		if dot < 0:
			vel -= n * dot * 1.2


func pick_up(kind: String) -> void:
	power = kind
	power_time = 999.0 if kind == "shield" else 8.0  # shield lasts until used

## DEPRECIATED. 
func drawSprite() -> void:
	if power == "pierce":
		Util.draw_sprite(self, _tex, Vector2.ZERO, 50, Color(3,3,0,1))
	else:if successfulhit == true:
			Util.draw_sprite(self, _tex, Vector2.ZERO, 38, Color(3,3,0,1))
	else:
		if invuln > 0 and int(floor(invuln * 12)) % 2 == 0:
			return  # flicker
		else:
			Util.draw_sprite(self, _tex, Vector2.ZERO, 38)
	

func _draw() -> void:	
	# flicker only when actually damaged, not during dash-granted invuln
	if hurt_flash > 0 and int(floor(hurt_flash * 12)) % 2 == 0:
		return
	# red tint for the first moments after losing a life
	var mod := Color.WHITE
	var additionalsize = 0
	if hurt_flash > 0:
		mod = Color(4.0, 0.45, 0.45)

	if successfulhit == true:
		mod = Color(2, 8, 0.5)

	if power == "pierce":
		additionalsize = 10

	Util.draw_shadow(self, Vector2.ZERO, 38 + additionalsize)

	# turbo: painted lightning streaks trailing behind the ball
	if power == "turbo" and vel.length() > 40.0:
		var back := -vel.normalized()
		var rot := vel.angle() + STREAK_ART_ANGLE
		var tms := Time.get_ticks_msec() / 1000.0
		for i in 3:
			var wob := sin(tms * 22.0 + i * 2.1)
			var at := back * (30.0 + i * 20.0) \
					+ back.orthogonal() * wob * 5.0
			var alpha := (0.85 - i * 0.22) * (0.7 + 0.3 * sin(tms * 30.0 + i))
			var size := 46.0 - i * 8.0
			draw_set_transform(at, rot, Vector2.ONE)
			draw_texture_rect(_tex_streak,
					Rect2(Vector2(-size, -size) / 2.0, Vector2(size, size)),
					false, Color(1, 1, 1, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_set_transform(Vector2.ZERO, roll, Vector2.ONE)
	Util.draw_sprite(self, _tex, Vector2.ZERO, 38 + additionalsize, mod)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# active power badge floats over your head, sprite instead of shapes
	if power == "shield" or power == "pierce":
		var badge := _tex_shield if power == "shield" else _tex_pierce
		var bob := sin(Time.get_ticks_msec() / 220.0) * 3.5
		var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 130.0)
		Util.draw_sprite(self, badge, Vector2(0, -48 + bob), 44.0 * pulse)
	# cooldown ring, full circle = dash ready
	if dash_cooldown > 0:
		var f := 1.0 - dash_cooldown / dash_cd_total
		draw_arc(Vector2.ZERO, 27, -PI / 2, -PI / 2 + f * TAU, 40, Color(0.176, 0.204, 0.212, 0.45), 3.0)
	
	
	
	#if power == "turbo":
		#if is_dashing == true:
			#var angle = (-vel).angle()
			#var randrotatedvector = Vector2.from_angle(angle + (randf_range(-1,1) * (PI/4)))
			#var lenght = vel.length()
			#var randlength = vel * randf()
			
			#draw_line(Vector2.ZERO,randrotatedvector*randlength,Color(0,0.8,0.8),10)
		
