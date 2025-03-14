extends Node

const SMALL_CARD_SCALE = 1.45
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 800

var battle_timer
var empty_weapon_card_slots: Array = []
var opponent_cards_on_battlefield: Array = []
var player_cards_on_battlefield: Array = []
var player_health
var opponent_health
var card_database_reference
var already_mid_range: bool
var already_dead_range: bool

func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_weapon_card_slots.append($"../CardSlots/EnemyCardSlot")
	
	card_database_reference = preload("res://assets/scripts/card_database.gd")
	
	player_health = STARTING_HEALTH
	$"../PlayerHealth".text = str(player_health)
	$"../HealthBar".max_value = STARTING_HEALTH
	$"../HealthBar".value = player_health
	
	opponent_health = STARTING_HEALTH
	$"../EnemyHealth".text = str(opponent_health)

func _on_end_turn_button_pressed() -> void:
	if player_cards_on_battlefield.size() > 0:
		var player_cards_to_attack = player_cards_on_battlefield.duplicate()
		for card in player_cards_to_attack:
			await direct_attack(card, "Player")
	opponent_turn()

func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	await wait(1.0)
	
	if $"../EnemyDeck".opponent_deck.size() != 0:
		$"../EnemyDeck".draw_card()
		await wait(1.0)
	
	if empty_weapon_card_slots.size() != 0:
		await try_play_card()
	
	if opponent_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			# if player_cards_on_battlefield.size() == 0:
			await direct_attack(card, "Opponent")
	
	end_opponent_turn()

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		player_health = max(0, player_health - attacking_card.damage)
		destroy_card(attacking_card, attacker)
		$"../PlayerHealth".text = str(player_health)
		
		var healthBarTween = create_tween()
		healthBarTween.set_ease(Tween.EASE_IN_OUT)
		healthBarTween.set_trans(Tween.TRANS_QUAD)
		healthBarTween.tween_property($"../HealthBar", "value", player_health, 0.4)
		if player_health < STARTING_HEALTH / 1.5:
			if player_health > STARTING_HEALTH / 3:
				if not already_mid_range:  # Ensures sound plays only when state changes
					already_mid_range = true
					already_dead_range = false
					$"../HealthBar".texture_under = load("res://assets/images/health-bar-nofill-mid.png")
					$"../AudioManager/midWarningSFX".play()
			elif not already_dead_range:
					already_mid_range = false
					already_dead_range = true
					$"../HealthBar".texture_under = load("res://assets/images/health-bar-nofill-angry.png")
					$"../AudioManager/critWarningSFX".play()
		else:
			already_mid_range = false
			already_dead_range = false
			$"../HealthBar".texture_under = load("res://assets/images/health-bar-nofill-happy.png")
	else:
		opponent_health = max(0, opponent_health - attacking_card.damage)
		destroy_card(attacking_card, attacker)
		$"../EnemyHealth".text = str(opponent_health)

func wait(wait_time: int):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func try_play_card():
	var enemy_hand = $"../EnemyHand".enemy_hand
	if enemy_hand.size() == 0:
		end_opponent_turn()
		return
	
	var random_empty_monster_card_slot = empty_weapon_card_slots.pick_random()
	empty_weapon_card_slots.erase(random_empty_monster_card_slot)
	
	var current_card_with_highest_dmg = enemy_hand[0]
	for card in enemy_hand:
		if card.damage > current_card_with_highest_dmg.damage:
			current_card_with_highest_dmg = card
	
	var tween = get_tree().create_tween()
	tween.tween_property(current_card_with_highest_dmg, "position", random_empty_monster_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(current_card_with_highest_dmg, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	current_card_with_highest_dmg.get_node("AnimationPlayer").play("card_flip")
	
	$"../EnemyHand".remove_card_from_hand(current_card_with_highest_dmg)
	current_card_with_highest_dmg.card_slot_card_is_in = random_empty_monster_card_slot
	opponent_cards_on_battlefield.append(current_card_with_highest_dmg)
	
	$"../AudioManager/cardPlaceSFX".play()
	
	await wait(1.0)

func end_opponent_turn():
	$"../Deck".reset_draw()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true

func destroy_card(card, card_owner):
	if card_owner == "Player":
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
	else:
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
			if card.card_slot_card_is_in and card.card_slot_card_is_in not in empty_weapon_card_slots:
				empty_weapon_card_slots.append(card.card_slot_card_is_in)
			
	card.card_slot_card_is_in.card_in_slot = false
	card.card_slot_card_is_in = null
	card.queue_free()
