extends TextureButton
## makes ui a bit bigger


func _ready() -> void:
	pivot_offset = size / 2.0
	mouse_entered.connect(func() -> void: scale = Vector2.ONE * 1.08)
	mouse_exited.connect(func() -> void: scale = Vector2.ONE)
