extends Node

func _ready() -> void:
	DiscordRPC.app_id = 1352388502146252810
	DiscordRPC.details = "Home"
	DiscordRPC.large_image = "icon-1024px"
	DiscordRPC.large_image_text = "Massacre your friends now!"
	
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	
	DiscordRPC.refresh() # Always refresh after changing the values!
