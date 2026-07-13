class_name FoodPlayer
extends Node2D

var game: Node

var vel := Vector2.ZERO
var radius := 14.0
var accel := 1600.0
var max_speed := 280.0
var friction := 4.5
var roll := 0.0
var max_lives := 3
var lives := 3
var invuln := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_cd_total := 0.85
var power := ""              # "", "turbo", "shield" or "pierce"
var power_time := 0.0

var _tex: Texture2D = preload("res://assets/player.png")


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
	dash_time = maxf(0, dash_time - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)

	if power != "":
		power_time -= dt
		if power_time <= 0:
			power = ""

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
		dash()

	queue_redraw()


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
	game.spawn_burst(position, Color("ff4757"), 20)
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


func _draw() -> void:
	if invuln > 0 and int(floor(invuln * 12)) % 2 == 0:
		return  # flicker
	Util.draw_shadow(self, Vector2.ZERO, 38)
	draw_set_transform(Vector2.ZERO, roll, Vector2.ONE)
	Util.draw_sprite(self, _tex, Vector2.ZERO, 38)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if power == "shield":
		draw_arc(Vector2.ZERO, radius + 7, 0, TAU, 40, Color(0.482, 0.929, 0.624, 0.8), 2.0)
	# cooldown ring, full circle = dash ready
	if dash_cooldown > 0:
		var f := 1.0 - dash_cooldown / dash_cd_total
		draw_arc(Vector2.ZERO, 27, -PI / 2, -PI / 2 + f * TAU, 40, Color(0.176, 0.204, 0.212, 0.45), 3.0)
