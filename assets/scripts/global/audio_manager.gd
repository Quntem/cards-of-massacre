extends Node

func _ready() -> void:
	update_volume()

func update_volume():
	AudioServer.set_bus_volume_db(0, Global.volume)
