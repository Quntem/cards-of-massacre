extends Node2D

const CARD_WIDTH: int = 130
const HAND_Y_POSITION: int = -30
const DEFAULT_CARD_MOVE_SPEED: float = 0.2

var enemy_hand: Array = []

func _ready() -> void:
	get_window().connect("size_changed", Callable(self, "_on_window_resized"))  # Detects window resizing

func add_card_to_hand(card, speed = DEFAULT_CARD_MOVE_SPEED):
	if card not in enemy_hand:
		enemy_hand.append(card)
	update_hand_positions(speed)

func _on_window_resized():
	update_hand_positions(0)  # Instantly reposition on resize

func update_hand_positions(speed):
	var viewport_size = get_viewport_rect().size  # Get live viewport size
	var center_screen_x = viewport_size.x / 2  # Correct center every frame
	var total_width = max((enemy_hand.size() - 1) * CARD_WIDTH, 0)  # Prevent negative width
	var start_x = center_screen_x - (total_width / 2)  # Corrected centering logic

	for i in range(enemy_hand.size()):
		var x_offset = start_x + (i * CARD_WIDTH)
		var new_position = Vector2(x_offset, HAND_Y_POSITION)
		var card = enemy_hand[i]

		# If resizing, instantly reposition. Otherwise, animate.
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
