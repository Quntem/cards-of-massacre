extends Label

const SPEED: int = 150
var dynamic_speed: float  # Adjust speed as necessary

func _ready() -> void:
	dynamic_speed = SPEED * (get_viewport_rect().size.x / 1920)

func _process(delta):
	position.x -= dynamic_speed * delta

	# Check if the right edge of the label is fully clipped by the parent
	if position.x + size.x < 0:
		queue_free()
