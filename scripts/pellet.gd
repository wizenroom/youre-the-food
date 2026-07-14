class_name PelletFood
extends Node2D
## Dropped food that snakes eat to grow (you can snack on it for points).

var radius := 6.0
var dead := false

var _phase := randf() * TAU
var _tex: Texture2D = preload("res://assets/pellet.png")


func _process(_dt: float) -> void:
	queue_redraw()  # bob is time-based, keeps animating even while paused


func _draw() -> void:
	var bob := sin(Time.get_ticks_msec() / 300.0 + _phase) * 10
	
	# shadow stays fixed
	Util.draw_shadow(self, Vector2(0, 4), 25, 0.6)
	
	# sprite floats
	Util.draw_sprite(self, _tex, Vector2(0, bob), 30)
