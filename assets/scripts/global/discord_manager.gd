extends Node

@export var details: String
@export var game: bool
@onready var timer = Timer.new()

func _ready() -> void:
	set_discord_details()
	DiscordRPC.app_id = 1352388502146252810
	DiscordRPC.large_image = "icon-1024px"
	DiscordRPC.large_image_text = "Massacre your friends now!"
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()

func _process(delta: float) -> void:
	set_discord_details()

func set_discord_details() -> void:
	DiscordRPC.details = details
	DiscordRPC.refresh()

func update_discord_health():
	if $"../BattleManager".player_health == 0:
		DiscordRPC.details = "Game Over (Lost in " + $"../BattleManager".turns + " turns)"
	else:
		DiscordRPC.details = "Game (" + str($"../BattleManager".player_health) + " / " + str($"../BattleManager".starting_health) + " HP)"
	DiscordRPC.refresh()
