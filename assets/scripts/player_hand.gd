extends Node2D

const CARD_WIDTH: int = 130
const DEFAULT_CARD_MOVE_SPEED: float = 0.2

var player_hand: Array = []

func add_card_to_hand(card, speed = DEFAULT_CARD_MOVE_SPEED):
	if card not in player_hand:
		player_hand.append(card)
	update_hand_positions(speed)

func update_hand_positions(speed):
	var screen_width = get_viewport_rect().size.x  # Dynamically get the screen width
	var screen_height = get_viewport_rect().size.y  # Dynamically get screen height
	var center_screen_x = screen_width / 2
	var hand_y_position = screen_height - 150  # Adjust Y position based on screen height
	
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	for i in range(player_hand.size()):
		var x_offset = center_screen_x + (i * CARD_WIDTH) - (total_width / 2)
		var new_position = Vector2(x_offset, hand_y_position)
		var card = player_hand[i]
		card.hand_position = new_position
		animate_card_to_position(card, new_position, speed)

func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card, "position", new_position, speed)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
