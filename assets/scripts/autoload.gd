extends Node

func _ready() -> void:
	print("Autoload ready, loading data...")
	Global.load_data()
	print("Data loaded.")
