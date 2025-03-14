extends TextureRect

@onready var rng = RandomNumberGenerator.new()

func _process(delta: float) -> void:
	$".".texture.noise.seed = rng.randi()
