extends Node

var save_path = "user://global.save"

var XP: int
var max_health: int = 800
var max_ammo: int = 5
var purchased_upgrades: Dictionary = {}  # Store purchased upgrades by ID

var absolute_db: bool
var volume: float
var very_precise: bool

func save_data():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(XP)
		file.store_var(max_health)
		file.store_var(max_ammo)
		file.store_var(absolute_db)
		file.store_var(volume)
		file.store_var(very_precise)
		file.store_var(purchased_upgrades)  # Save purchased upgrades
		file.close()  # Ensure the file is properly closed after writing
	else:
		print("Failed to open file for saving data.")

func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			XP = file.get_var(XP)
			max_health = file.get_var(max_health)
			max_ammo = file.get_var(max_ammo)
			absolute_db = file.get_var(absolute_db)
			volume = file.get_var(volume)
			very_precise = file.get_var(very_precise)
			purchased_upgrades = file.get_var()

			# Ensure `purchased_upgrades` is a dictionary to prevent errors
			if typeof(purchased_upgrades) != TYPE_DICTIONARY:
				purchased_upgrades = {}
			file.close()  # Ensure the file is properly closed after reading
