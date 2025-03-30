extends Node2D

const CARD_WIDTH: int = 130
const HAND_Y_POSITION: int = 50  # Adjust Y position for enemy hand
const DEFAULT_CARD_MOVE_SPEED: float = 0.2

var enemy_hand: Array = []

func _ready() -> void:
	# Correct signal connection with Callable
	get_viewport().connect("size_changed", Callable(self, "_on_window_resized"))

func add_card_to_hand(card, speed = DEFAULT_CARD_MOVE_SPEED):
	if card not in enemy_hand:
		enemy_hand.append(card)
	update_hand_positions(speed)

func _on_window_resized():
	update_hand_positions(0)  # Instantly reposition on resize

func update_hand_positions(speed):
	var screen_width = get_viewport_rect().size.x  # Dynamically get the screen width
	var center_screen_x = screen_width / 2.0  # Ensure floating-point division
	
	var card_count = enemy_hand.size()
	if card_count == 0:
		return
	
	# Use card_count - 1 so that a single card is centered exactly
	var total_width = (card_count - 1) * CARD_WIDTH
	var start_x = center_screen_x - (total_width / 2.0)
	
	for i in range(card_count):
		var x_offset = start_x + (i * CARD_WIDTH)
		var new_position = Vector2(x_offset, HAND_Y_POSITION)
		var card = enemy_hand[i]
		if speed > 0:
			animate_card_to_position(card, new_position, speed)
		else:
			card.position = new_position  # Instantly place during resize

func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card, "position", new_position, speed)

func remove_card_from_hand(card):
	if card in enemy_hand:
		enemy_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
