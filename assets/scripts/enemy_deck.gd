extends Node2D

const CARD_SCENE_PATH = "res://assets/scenes/subscene/enemy_card.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTER_HAND_SIZE = 4

# Constants for positioning
const CARD_WIDTH: int = 130
const CARD_SCALE: Vector2 = Vector2(1.5, 1.5)  # Ensuring correct scale

var opponent_deck: Array = ["shotgun-card", "shotgun-card", "shotgun-card", "ammo-card-1", "ammo-card-2", "ammo-card-2"]
var enemy_hand: Array = []  
var empty_weapon_card_slots: Array = []  
var opponent_cards_on_battlefield: Array = []  
var card_database_reference

func _ready() -> void:
	opponent_deck.shuffle()
	card_database_reference = preload("res://assets/scripts/card_database.gd")
	empty_weapon_card_slots.append($"../CardSlots/EnemyCardSlot")  
	
	for i in range(STARTER_HAND_SIZE):
		draw_card()
		await get_tree().create_timer(.2).timeout

func draw_card():
	if opponent_deck.is_empty():
		return
	
	var card_drawn_name = opponent_deck.pop_front()
	$"../AudioManager/cardSwipeSFX".play()
	
	if opponent_deck.is_empty():
		$Sprite2D.visible = false
	
	# Create the card instance
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = "res://assets/images/" + card_drawn_name + ".png"
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.damage = card_database_reference.CARDS[card_drawn_name][0]
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][3]
	
	# Apply correct scale
	new_card.scale = CARD_SCALE

	# Add card to scene
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	
	# Add to hand
	add_card_to_hand(new_card, CARD_DRAW_SPEED)

func add_card_to_hand(card, speed):
	enemy_hand.append(card)
	update_hand_positions(speed)

func update_hand_positions(speed):
	var screen_width = get_window().size.x
	var total_width = (enemy_hand.size() - 1) * CARD_WIDTH
	var center_screen_x = screen_width / 2

	# Set Y position so the cards are visible at the top
	var hidden_y_position = 125  # Adjust this value

	for i in range(enemy_hand.size()):
		var x_offset = center_screen_x - (i * CARD_WIDTH) + (total_width / 2)
		var new_position = Vector2(x_offset, hidden_y_position)
		enemy_hand[i].hand_position = new_position
		animate_card_to_position(enemy_hand[i], new_position, speed)

func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card, "position", new_position, speed)

func remove_card_from_hand(card):
	enemy_hand.erase(card)
	update_hand_positions(CARD_DRAW_SPEED)

# Opponent places a card
func try_play_card():
	if enemy_hand.is_empty() or empty_weapon_card_slots.is_empty():
		return
	
	var random_empty_slot = empty_weapon_card_slots.pick_random()
	empty_weapon_card_slots.erase(random_empty_slot)
	
	# Find the best card
	var best_card = enemy_hand[0]
	for card in enemy_hand:
		if card.damage > best_card.damage:
			best_card = card
	
	# Move the card to the battlefield
	var tween = get_tree().create_tween()
	tween.tween_property(best_card, "position", random_empty_slot.position, CARD_DRAW_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(best_card, "scale", CARD_SCALE, CARD_DRAW_SPEED)  # Scale applied again
	best_card.get_node("AnimationPlayer").play("card_flip")

	# Remove from hand
	remove_card_from_hand(best_card)
	best_card.card_slot_card_is_in = random_empty_slot
	opponent_cards_on_battlefield.append(best_card)

	$"../AudioManager/cardPlaceSFX".play()

	await get_tree().create_timer(1.0).timeout
	print("Card played: ", best_card.name, " Position: ", best_card.position)
