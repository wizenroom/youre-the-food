class_name CritterEnemy
extends Node2D

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/critter_circle.png"),
	preload("res://assets/critter_square.png"),
	preload("res://assets/critter_triangle.png"),
	preload("res://assets/critter_pentagon.png"),
	preload("res://assets/critter_diamond.png"),
]

const WAKE_TIME := 0.9       # harmless and frozen while hatching
const LIFETIME := 14.0
const DRAW_SIZE := 24.0

var game: Node
var dead := false
var radius := 9.0
var speed := 110.0
var age := 0.0

var _tex: Texture2D = TEXTURES[randi() % TEXTURES.size()]
var _wobble := randf() * TAU


func setup(g: Node, pos: Vector2, spd: float) -> void:
	game = g
	position = pos
	speed = spd


func awake() -> bool:
	return age >= WAKE_TIME


func update(dt: float) -> void:
	age += dt
	if age >= LIFETIME:
		die()
		return
	if awake():
		# chase with a sideways oscillation
		var dir: Vector2 = (game.player.position - position).normalized()
		var side := Vector2(-dir.y, dir.x) * sin(age * 9.0 + _wobble) * 22.0
		position += (dir * speed + side) * dt
		position.x = clampf(position.x, radius, game.WORLD_W - radius)
		position.y = clampf(position.y, radius, game.WORLD_H - radius)
	queue_redraw()


func die() -> void:
	if dead:
		return
	dead = true
	game.spawn_burst(position, Color("ff6348"), 5)
	queue_free()


func _draw() -> void:
	# flicker before despawning
	if LIFETIME - age < 2.0 and int(floor(age * 8)) % 2 == 0:
		return
	var pop := minf(1.0, age / WAKE_TIME)
	var size := DRAW_SIZE * (0.4 + 0.6 * pop)
	# tremble while hatching
	var shake := Vector2.ZERO
	if not awake():
		shake = Vector2(sin(age * 40.0), cos(age * 34.0)) * 1.5
	Util.draw_shadow(self, Vector2(0, 4), size * 0.9, 0.6)
	draw_set_transform(shake, sin(age * 9.0 + _wobble) * 0.2, Vector2.ONE)
	Util.draw_sprite(self, _tex, Vector2.ZERO, size)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
