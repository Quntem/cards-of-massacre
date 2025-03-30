extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const CARD_SMALLER_SCALE = 1.45

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var player_weapon_card_this_turn

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", Callable(self, "on_left_click_released"))
	center_cards_in_hand()

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))
	update_card_tilts()

func start_drag(card):
	if (card.ammo_req <= $"../BattleManager".player_ammo) or (card.ammo_req == 0):
		DiscordRPC.state = "Dragging Card"
		DiscordRPC.refresh()
		card_being_dragged = card
		card.scale = Vector2(1.5, 1.5)

func finish_drag():
	DiscordRPC.state = "Idle"
	DiscordRPC.refresh()
	var card_slot_found = check_card_slot_via_raycast()
	if card_slot_found and not card_slot_found.card_in_slot:
		card_being_dragged.scale = Vector2(1.4, 1.4)
		card_being_dragged.z_index = -1
		card_being_dragged.card_slot_card_is_in = card_slot_found
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		card_being_dragged.position = card_slot_found.position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		card_slot_found.card_in_slot = true
		$"../BattleManager".player_cards_on_battlefield.append(card_being_dragged)
		card_being_dragged.get_node("CardOutline").modulate = Color(1, 1, 1, 0)
		$"../AudioManager/cardPlaceSFX".play()
		DiscordRPC.state = "Placed Card"
		DiscordRPC.refresh()
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null
	center_cards_in_hand()
	
	await get_tree().create_timer(1.0).timeout
	DiscordRPC.state = "Idle"
	DiscordRPC.refresh()

func connect_card_signals(card):
	card.connect("hovered", Callable(self, "on_hovered_over_card"))
	card.connect("hovered_off", Callable(self, "on_hovered_off_card"))

func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func on_hovered_over_card(card):
	if not is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if not card.card_slot_card_is_in and not card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = check_card_via_raycast()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false

func highlight_card(card, hovered):
	if hovered:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(card, "scale", Vector2(1.6, 1.6), 0.08)
		var tween2 = create_tween()
		tween2.set_ease(Tween.EASE_IN)
		tween2.set_trans(Tween.TRANS_QUAD)
		tween2.tween_property(card.get_node("CardOutline"), "modulate", Color(1, 1, 1, 1), 0.08)
		card.z_index = 2
	else:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(card, "scale", Vector2(1.5, 1.5), 0.08)
		var tween2 = create_tween()
		tween2.set_ease(Tween.EASE_IN)
		tween2.set_trans(Tween.TRANS_QUAD)
		tween2.tween_property(card.get_node("CardOutline"), "modulate", Color(1, 1, 1, 0), 0.08)
		card.scale = Vector2(1.5, 1.5)
		card.z_index = 1

func check_card_slot_via_raycast():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func check_card_via_raycast():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card

func center_cards_in_hand():
	var screen_width = get_viewport().size.x
	var hand = player_hand_reference.get_children()
	if hand.size() == 0:
		return

	var card_width = 100 * CARD_SMALLER_SCALE  # Assuming each card's width is 100 and scale is 1.45
	var total_width = (card_width * hand.size()) + (20 * (hand.size() - 1))  # 20 is the spacing between cards
	var start_x = (screen_width - total_width) / 2

	for i in range(hand.size()):
		var card = hand[i]
		card.position.x = start_x + i * (card_width + 20)
		card.position.y = screen_size.y - 200  # Adjust Y position as needed

func update_card_tilts():
	var mouse_pos = get_global_mouse_position()
	var hand = player_hand_reference.get_children()
	for card in hand:
		var direction = (mouse_pos - card.position).normalized()
		card.rotation = direction.angle()
