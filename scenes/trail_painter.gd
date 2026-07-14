extends Sprite2D

var image: Image
var texture_image: ImageTexture
@onready var background = get_parent()

const SIZE := Vector2i(3904, 2944)

@export var decay: float = 0.99
@export var trail_scale: int = 16

var TRAIL_SIZE := SIZE / trail_scale

func _ready():
	image = Image.create(TRAIL_SIZE.x, TRAIL_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	texture_image = ImageTexture.create_from_image(image)
	texture = texture_image

	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scale = Vector2(trail_scale, trail_scale)

func _process(delta):
	fade_trail()

func fade_trail():
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var c := image.get_pixel(x, y)
			c.a *= decay
			image.set_pixel(x, y, c)

	texture_image.update(image)

func stamp(pos: Vector2, radius: int = 8):
	var center := Vector2i(pos / trail_scale)
	var scaled_radius := radius / trail_scale

	for x in range(-scaled_radius, scaled_radius + 1):
		for y in range(-scaled_radius, scaled_radius + 1):
			if x * x + y * y <= scaled_radius * scaled_radius:
				var p := center + Vector2i(x, y)

				if p.x >= 0 and p.x < TRAIL_SIZE.x and p.y >= 0 and p.y < TRAIL_SIZE.y:
					image.set_pixelv(p, Color.RED)

	texture_image.update(image)
