extends Node

var save_path = "user://global.save"

var XP: int
var max_health: int = 800
var max_ammo: int = 5
var purchased_upgrades: Dictionary = {}  # Store purchased upgrades by ID

func save_data():
	print("Saving data...")
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		print("Saving XP: %d" % XP)
		file.store_var(XP)
		file.store_var(max_health)
		file.store_var(max_ammo)
		file.store_var(purchased_upgrades)  # Save purchased upgrades
		file.close()  # Ensure the file is properly closed after writing
		print("Data saved successfully.")
	else:
		print("Failed to open file for saving data.")

func load_data():
	print("Loading data...")
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			XP = file.get_var(XP)
			print("Loaded XP: %d" % XP)
			max_health = file.get_var(max_health)
			max_ammo = file.get_var(max_ammo)
			purchased_upgrades = file.get_var()

			# Ensure `purchased_upgrades` is a dictionary to prevent errors
			if typeof(purchased_upgrades) != TYPE_DICTIONARY:
				purchased_upgrades = {}
			file.close()  # Ensure the file is properly closed after reading
			print("Data loaded successfully.")
			update_display()  # Update the display/UI after loading data
		else:
			print("Failed to open file for loading data.")
	else:
		print("No data saved at " + save_path)

# Function to update the display/UI
func update_display():
	print("Updating display with XP: %d" % XP)
