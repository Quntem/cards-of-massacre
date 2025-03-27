extends Camera2D

@export var drag_speed = 0.8
@export var zoom_speed = 0.1
var dragging: bool = false
var drag_start_position: Vector2
var drag_start_camera_position: Vector2
var target_position: Vector2
var space_held_time: float = 0.0
var space_hold_duration: float = 0.75  # Duration to hold the space bar in seconds

# Reference to ColorRect node
@onready var background = $"../Background"

func _ready():
	# Center the camera on the screen's center position
	global_position = get_viewport_rect().size / 2
	target_position = global_position

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if the mouse is over a button
				dragging = true
				drag_start_position = event.position
				drag_start_camera_position = target_position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		var drag_delta = (event.position - drag_start_position) * drag_speed
		target_position = drag_start_camera_position - drag_delta

func _process(_delta):
	global_position = global_position.lerp(target_position, 0.001)
	background.position = global_position - (background.size / 2)
	
	if Input.is_key_pressed(KEY_SPACE):
		space_held_time += _delta
		if space_held_time >= space_hold_duration:
			target_position = get_viewport_rect().size / 2
			space_held_time = 0.0  # Reset the timer after returning to the start position
	else:
		space_held_time = 0.0  # Reset the timer if the space bar is not pressed
