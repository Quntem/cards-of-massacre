extends Button

@export var animation_player: AnimationPlayer

func _on_pressed() -> void:
	animation_player.play("circle_transition")
	await animation_player.animation_finished
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://assets/scenes/menu.tscn")
