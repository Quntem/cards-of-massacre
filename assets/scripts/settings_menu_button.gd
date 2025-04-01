extends Button

@onready var circle_transition_player: AnimationPlayer = $"../../../CircleTransition/CircleTransitionPlayer"

func _on_button_up() -> void:
	var parent = get_parent()
	for child in parent.get_children():
		if child is Button:
			child.disabled = true
	circle_transition_player.play("circle_transition")
	await circle_transition_player.animation_finished
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://assets/scenes/settings.tscn")
