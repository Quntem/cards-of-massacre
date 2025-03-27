extends Node

var save_path = "user://global.save"

var XP: int

func save_data():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(XP)

func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		XP = file.get_var(XP)
	else:
		print("No data saved at " + save_path)
