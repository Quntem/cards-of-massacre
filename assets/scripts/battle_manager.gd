extends Node

const SMALL_CARD_SCALE = Vector2(1.5, 1.5)  # Ensuring correct scale
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 800
const XP_AMOUNT = 2000

var battle_timer
var empty_weapon_card_slots: Array = []
var opponent_cards_on_battlefield: Array = []
var player_cards_on_battlefield: Array = []
var player_health
var opponent_health
var card_database_reference
var already_mid_range: bool
var already_dead_range: bool
var opponent_deck
var cards_used: int = 0

func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0

	empty_weapon_card_slots.append($"../CardSlots/EnemyCardSlot")

	card_database_reference = preload("res://assets/scripts/card_database.gd")

	player_health = STARTING_HEALTH
	$"../HealthBar".max_value = STARTING_HEALTH
	$"../HealthBar".value = player_health

	opponent_health = STARTING_HEALTH

	opponent_deck = $"../EnemyDeck"

func _on_end_turn_button_pressed() -> void:
	# Disable the end turn button immediately to prevent multiple presses
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false

	execute_player_actions()
	await wait(1.0)
	await opponent_turn()
	end_opponent_turn()

func execute_player_actions() -> void:
	if player_cards_on_battlefield.size() > 0:
		var player_cards_to_attack = player_cards_on_battlefield.duplicate()
		for card in player_cards_to_attack:
			await direct_attack(card, "Player")
			cards_used += 1

func opponent_turn() -> void:
	await wait(1.0)

	if opponent_deck.opponent_deck.size() != 0:
		opponent_deck.draw_card()
		await wait(1.0)

	if empty_weapon_card_slots.size() != 0:
		await try_play_card()

	if opponent_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			await direct_attack(card, "Opponent")

func direct_attack(attacking_card, attacker) -> void:
	if attacking_card.card_name == "shotgun-card":
		$"../AudioManager/shotgunFireSFX".play()
		
		var shotgun = $"../CanvasLayer/Shotgun"
		
		var fadeInTween = get_tree().create_tween()
		fadeInTween.set_ease(Tween.EASE_IN_OUT)
		fadeInTween.set_trans(Tween.TRANS_QUAD)
		fadeInTween.tween_property(shotgun, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
		
		var fadeInDarkenerTween = get_tree().create_tween()
		fadeInDarkenerTween.set_ease(Tween.EASE_IN_OUT)
		fadeInDarkenerTween.set_trans(Tween.TRANS_QUAD)
		fadeInDarkenerTween.tween_property($"../CanvasLayer/Darkener", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
		
		if attacker == "Player":
			var rotateLeft = get_tree().create_tween()
			rotateLeft.set_ease(Tween.EASE_IN_OUT)
			rotateLeft.set_trans(Tween.TRANS_QUAD)
			rotateLeft.tween_property(shotgun, "rotation", deg_to_rad(-90), 0.6)
			
			await rotateLeft.finished # about 0.8 seconds
			
			var knockBack = get_tree().create_tween()
			knockBack.set_ease(Tween.EASE_IN_OUT)
			knockBack.set_trans(Tween.TRANS_QUAD)
			knockBack.tween_property(shotgun, "position", Vector2(shotgun.position.x, 720), 0.1)
			
			await knockBack.finished
			
			var knockBackR = get_tree().create_tween()
			knockBackR.set_ease(Tween.EASE_IN_OUT)
			knockBackR.set_trans(Tween.TRANS_QUAD)
			knockBackR.tween_property(shotgun, "position", Vector2(shotgun.position.x, 540), 0.8)
		else:
			var rotateRight = get_tree().create_tween()
			rotateRight.set_ease(Tween.EASE_IN_OUT)
			rotateRight.set_trans(Tween.TRANS_QUAD)
			rotateRight.tween_property(shotgun, "rotation", deg_to_rad(90), 0.6)
			
			await rotateRight.finished # about 0.8 seconds
			
			var knockBack = get_tree().create_tween()
			knockBack.set_ease(Tween.EASE_IN_OUT)
			knockBack.set_trans(Tween.TRANS_QUAD)
			knockBack.tween_property(shotgun, "position", Vector2(shotgun.position.x, 360), 0.1)
			
			await knockBack.finished
			
			var knockBackR = get_tree().create_tween()
			knockBackR.set_ease(Tween.EASE_IN_OUT)
			knockBackR.set_trans(Tween.TRANS_QUAD)
			knockBackR.tween_property(shotgun, "position", Vector2(shotgun.position.x, 540), 0.8)
		
		var fadeOutTween = get_tree().create_tween()
		fadeOutTween.set_ease(Tween.EASE_IN_OUT)
		fadeOutTween.set_trans(Tween.TRANS_QUAD)
		fadeOutTween.tween_property(shotgun, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
		
		var fadeOutDarkenerTween = get_tree().create_tween()
		fadeOutDarkenerTween.set_ease(Tween.EASE_IN_OUT)
		fadeOutDarkenerTween.set_trans(Tween.TRANS_QUAD)
		fadeOutDarkenerTween.tween_property($"../CanvasLayer/Darkener", "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
		
		await $"../AudioManager/shotgunFireSFX".finished # about 2.04 seconds
		
	if attacker == "Opponent":
		player_health = max(0, player_health - attacking_card.damage)
		destroy_card(attacking_card, attacker)

		var healthBarTween = create_tween()
		healthBarTween.set_ease(Tween.EASE_IN_OUT)
		healthBarTween.set_trans(Tween.TRANS_QUAD)
		healthBarTween.tween_property($"../HealthBar", "value", player_health, 0.4)
		if player_health < STARTING_HEALTH / 1.5:
			if player_health > STARTING_HEALTH / 3.0:  # Ensure floating-point division
				if not already_mid_range:
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
		
		if player_health == 0:
			await healthBarTween.finished
			game_over()
	else:
		opponent_health = max(0, opponent_health - attacking_card.damage)
		destroy_card(attacking_card, attacker)
		
		var oppHealthBarTween = create_tween()
		oppHealthBarTween.set_ease(Tween.EASE_IN_OUT)
		oppHealthBarTween.set_trans(Tween.TRANS_QUAD)
		oppHealthBarTween.tween_property($"../EnemyHealthBar", "value", opponent_health, 0.4)
		
	await get_tree().create_timer(0.5).timeout  # Slight delay to visualize the attack

func wait(wait_time: float) -> void:
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func try_play_card() -> void:
	var enemy_hand = opponent_deck.enemy_hand
	if enemy_hand.size() == 0:
		return
	
	if empty_weapon_card_slots.size() == 0:
		return
	
	var random_empty_monster_card_slot = empty_weapon_card_slots.pick_random()
	empty_weapon_card_slots.erase(random_empty_monster_card_slot)
	
	var best_card_to_place = enemy_hand[0]
	for card in enemy_hand:
		if card.damage > best_card_to_place.damage:
			best_card_to_place = card
	
	if best_card_to_place.damage == 0:
		for card in enemy_hand:
			if card.ammo > best_card_to_place.ammo:
				best_card_to_place = card
	
	var tween = get_tree().create_tween()
	tween.tween_property(best_card_to_place, "position", random_empty_monster_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(best_card_to_place, "scale", SMALL_CARD_SCALE, CARD_MOVE_SPEED)
	best_card_to_place.get_node("AnimationPlayer").play("card_flip")

	opponent_deck.remove_card_from_hand(best_card_to_place)
	best_card_to_place.card_slot_card_is_in = random_empty_monster_card_slot
	opponent_cards_on_battlefield.append(best_card_to_place)
	
	$"../AudioManager/cardPlaceSFX".play()
	
	await wait(1.0)

func end_opponent_turn() -> void:
	$"../Deck".reset_draw()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true

func destroy_card(card, card_owner) -> void:
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

func game_over():
	$"../HealthBar".texture_under = load("res://assets/images/health-bar-nofill-dead.png")
	$"../AudioManager/gameOverSFX".play()
	var deathDarkenerFadeIn = create_tween()
	deathDarkenerFadeIn.set_ease(Tween.EASE_IN_OUT)
	deathDarkenerFadeIn.set_trans(Tween.TRANS_QUAD)
	deathDarkenerFadeIn.tween_property($"../DeathUI/Darkener", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	await deathDarkenerFadeIn.finished
	
	var skullFadeIn = create_tween()
	skullFadeIn.set_ease(Tween.EASE_IN_OUT)
	skullFadeIn.set_trans(Tween.TRANS_QUAD)
	skullFadeIn.tween_property($"../DeathUI/Skull", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	await skullFadeIn.finished
	await $"../AudioManager/gameOverSFX".finished
	
	var skullFadeOut = create_tween()
	skullFadeOut.set_ease(Tween.EASE_IN_OUT)
	skullFadeOut.set_trans(Tween.TRANS_QUAD)
	skullFadeOut.tween_property($"../DeathUI/Skull", "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
	await skullFadeOut.finished
	
	var textFadeIn = create_tween()
	textFadeIn.set_ease(Tween.EASE_IN_OUT)
	textFadeIn.set_trans(Tween.TRANS_QUAD)
	textFadeIn.tween_property($"../DeathUI/XP", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	await textFadeIn.finished
	
	# Ensure cards_used is at least 1 to avoid division by zero
	var cards_used_divided_by_eight = max(1, float(max(1, cards_used)) / 8.0)
	print(cards_used_divided_by_eight)
	$"../DeathUI/XP".text = str(int(max(0, XP_AMOUNT / cards_used_divided_by_eight * 0.5)))
	
	get_tree().paused = true
