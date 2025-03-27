extends Button
class_name upgrade_node

@export var xp_required: int = -1  # Set default to -1 to catch unset values
@export var title: String
@export_multiline var description: String
@export var image: Texture2D

@export var max_health_increase: int
@export var max_mag_increase: int

@onready var panel: Panel = $Panel
@onready var line_2d: Line2D = $Line2D

var purchased: bool = false

func _ready() -> void:
	get_node("Title").text = title
	get_node("Desc").text = description
	get_node("Icon").texture = image
	
	# Check if the upgrade was already purchased
	if title in Global.purchased_upgrades and Global.purchased_upgrades[title]:
		apply_upgrade()  # Apply the upgrade immediately
		purchased = true
		disable_upgrade()

	# If this upgrade has a parent, draw a connection line
	if get_parent() is upgrade_node:
		line_2d.clear_points()
		var start_point = global_position + size / 2
		var end_point = get_parent().global_position + size / 2
		line_2d.add_point(start_point)
		line_2d.add_point(end_point)

func _on_pressed() -> void:
	if purchased:
		return  # Prevent repurchasing

	if xp_required <= 0:
		return  # Prevent purchasing if XP requirement is invalid

	if Global.XP >= xp_required:
		Global.XP -= xp_required
		apply_upgrade()

		# Mark as purchased and save
		Global.purchased_upgrades[title] = true
		Global.save_data()

		disable_upgrade()

func apply_upgrade():
	if max_health_increase != 0:
		Global.max_health += max_health_increase
	if max_mag_increase != 0:
		Global.max_ammo += max_mag_increase

func disable_upgrade():
	panel.z_index = -1
	panel.show_behind_parent = true
	line_2d.modulate = Color(1, 1, 1, 1)
	disabled = true  # Prevent further purchases

	# Enable connected upgrades
	var upgrades = get_children()
	for upgrade in upgrades:
		if upgrade is upgrade_node:
			upgrade.disabled = false
