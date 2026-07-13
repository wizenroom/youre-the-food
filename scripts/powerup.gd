class_name PowerUpPickup
extends Node2D
## Pickup dropped by severed snake bodies: turbo, shield or pierce.

const KINDS := ["turbo", "shield", "pierce"]
const TEXTURES := {
	"turbo": preload("res://assets/powerup_turbo.png"),
	"shield": preload("res://assets/powerup_shield.png"),
	"pierce": preload("res://assets/powerup_pierce.png"),
}

var kind: String = KINDS[randi() % KINDS.size()]
var radius := 14.0
var life := 9.0
var dead := false


func update(dt: float) -> void:
	life -= dt
	if life <= 0:
		dead = true
		queue_free()


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if life < 3 and int(floor(life * 8)) % 2 == 0:
		return  # expiry flicker
	var bob := sin(Time.get_ticks_msec() / 250.0) * 3.0
	Util.draw_shadow(self, Vector2(0, 8), 24, 0.6)
	Util.draw_sprite(self, TEXTURES[kind], Vector2(0, bob), 100)
