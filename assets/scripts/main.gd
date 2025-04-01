extends Node

func _ready() -> void:
	AudioManager.update_volume()
	AudioPlayer.end_home_music()
	$CircleTransition.material.set_shader_parameter("screen_width", get_viewport().size.x)
	$CircleTransition.material.set_shader_parameter("screen_height", get_viewport().size.y)
	$CircleTransition.material.set_shader_parameter("circle_size", 0)
	$CircleTransition/CircleTransitionPlayer.play_backwards("circle_transition")
