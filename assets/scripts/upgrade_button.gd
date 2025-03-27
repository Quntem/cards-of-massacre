extends Button

@export var xp_required: int
@onready var panel: Panel = $Panel

func _on_pressed() -> void:
	if Global.XP >= xp_required:
		Global.XP -= xp_required
		Global.save_data()
		
		panel.z_index = -1
		panel.show_behind_parent = true
	else:
		print("you need more xp...")
