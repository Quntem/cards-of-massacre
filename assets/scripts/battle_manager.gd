extends Node

# onready stuff
@onready var ammo_container = $"../MatchUI/AmmoContainer"
@onready var ammo_icons = ammo_container.get_children()

@onready var opp_ammo_container = $"../MatchUI/EnemyAmmoContainer"
@onready var opp_ammo_icons = opp_ammo_container.get_children()

# constant stuff
const CARD_MOVE_SPEED: float = 0.2
const SKIP_PENALTY_FACTOR: float = 0.1
const ROUND_PENALTY_FACTOR: float = 1.05

const SMALL_CARD_SCALE: Vector2 = Vector2(1.5, 1.5)
const BASE_XP: int = 500
const XP_AMOUNT: int = 2000
const TURN_BONUS: int = 100

# variable stuff
var battle_timer: Timer
var opponent_deck: Node2D

var empty_weapon_card_slots: Array = []
var opponent_cards_on_battlefield: Array = []
var player_cards_on_battlefield: Array = []

var already_mid_range: bool = false
var already_dead_range: bool = false

var player_max_ammo: int
var max_ammo: int = 5
var starting_health: int = Global.max_health
var player_health: int = starting_health
var opponent_health: int = 800
var ammo_cards_used: int = 0
var attack_cards_used: int = 0
var skipped_turns: int = 0
var turns: int = 0
var game_ended: bool = false
var player_ammo: int = 0
var opponent_ammo: int = 0

var card_database_reference: Script = preload("res://assets/scripts/card_database.gd")

func _ready() -> void:
	# variables
	player_max_ammo = Global.max_ammo
	
	# object loads
	battle_timer = $"../BattleTimer"
	opponent_deck = $"../EnemyDeck"
	empty_weapon_card_slots.append($"../CardSlots/EnemyCardSlot")
	
	# set health bar stuff
	$"../MatchUI/HealthBar".max_value = starting_health
	$"../MatchUI/HealthBar".value = player_health
	
	update_ammo_display()
	update_enemy_ammo_display()
	
	$"../DiscordManager".update_discord_health()

func _on_end_turn_button_pressed() -> void:
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	turns += 1
	
	await execute_player_actions()
	await wait(1.0)
	await opponent_turn()
	end_opponent_turn()
	check_for_usuable_cards()

func execute_player_actions() -> void:
	if game_ended: return
	
	if player_cards_on_battlefield:
		DiscordRPC.state = "Ended Turn"
		DiscordRPC.refresh()
		for card in player_cards_on_battlefield.duplicate():
			if card.card_type == "Attack" && player_ammo > card.ammo_req:
				await direct_attack(card, "Player")
			elif card.card_type == "Attack":
				attack_cards_used += 1
			elif card.card_type == "Ammo":
				ammo_cards_used += 1
				add_ammo(card.ammo, "Player")
				destroy_card(card, "Player")
	else:
		DiscordRPC.state = "Skipped Turn"
		DiscordRPC.refresh()
		skipped_turns += 1

func opponent_turn() -> void:
	if game_ended: return
	
	DiscordRPC.state = "Opponent's Turn"
	DiscordRPC.refresh()
	
	await wait(1.0)
	if turns > 1 and opponent_deck.opponent_deck:
		opponent_deck.draw_card()
		await wait(1.0)
	if empty_weapon_card_slots:
		await try_play_card()
	if opponent_cards_on_battlefield:
		for card in opponent_cards_on_battlefield.duplicate():
			await direct_attack(card, "Opponent")

func direct_attack(attacking_card, attacker) -> void:
	if attacking_card.card_type == "Attack":
		DiscordRPC.state = attacker + " attacks!"
		DiscordRPC.refresh()
		if player_ammo > 0 || opponent_ammo > 0:
			if attacking_card.card_name == "Shotgun":
				$"../AudioManager/shotgunFireSFX".play()
			elif attacking_card.card_name == "Rifle":
				$"../AudioManager/rifleFireSFX".play()
			elif attacking_card.card_name == "Pistol":
				$"../AudioManager/pistolFireSFX".play()
			
			await play_attack_animation(attacker, attacking_card)
			if attacker == "Player":
				add_ammo(-attacking_card.ammo_req, "Player")
			else:
				add_ammo(-attacking_card.ammo_req, "Opponent")
		else:
			return
	
	if attacker == "Opponent":
		update_health("Player", attacking_card.damage)
	else:
		update_health("Opponent", attacking_card.damage)
	
	destroy_card(attacking_card, attacker)
	await wait(0.5)

func update_health(target: String, damage: int):
	if target == "Player":
		player_health = max(0, player_health - damage)
		update_health_bar($"../MatchUI/HealthBar", player_health, target)
		if player_health == 0:
			game_over()
		$"../DiscordManager".update_discord_health()
	else:
		opponent_health = max(0, opponent_health - damage)
		update_health_bar($"../MatchUI/EnemyHealthBar", opponent_health, target)
		if opponent_health == 0:
			win()

func update_health_bar(health_bar, health: int, target):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(health_bar, "value", health, 0.4)
	
	if target == "Player":
		if player_health < starting_health / 1.5:
			if player_health > starting_health / 3.0 && !already_mid_range:  # Ensure floating-point division
				already_mid_range = true
				already_dead_range = false
				$"../MatchUI/HealthBar".texture_under = load("res://assets/images/health-bar-nofill-mid.png")
				$"../AudioManager/midWarningSFX".play()
				
			elif !already_dead_range:
				already_mid_range = false
				already_dead_range = true
				$"../MatchUI/HealthBar".texture_under = load("res://assets/images/health-bar-nofill-angry.png")
				$"../AudioManager/critWarningSFX".play()
		else:
			already_mid_range = false
			already_dead_range = false
			$"../MatchUI/HealthBar".texture_under = load("res://assets/images/health-bar-nofill-happy.png")

func wait(wait_time: float) -> void:
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func try_play_card() -> void:
	var enemy_hand = opponent_deck.enemy_hand
	if enemy_hand.is_empty() or empty_weapon_card_slots.is_empty():
		return
	
	var slot = empty_weapon_card_slots.pop_front()
	var best_card = enemy_hand.reduce(
		func(best, current): 
			return current if current.damage > best.damage or (current.damage == best.damage and current.ammo > best.ammo) else best,
		enemy_hand[0]
	)
	
	if best_card.card_type == "Attack" and opponent_ammo < 1:
		for card in enemy_hand:
			if card.card_type == "Ammo":
				best_card = card
				add_ammo(card.ammo, "Opponent")
				break
	
	var tween = get_tree().create_tween()
	tween.tween_property(best_card, "position", slot.position, CARD_MOVE_SPEED)
	tween.tween_property(best_card, "scale", SMALL_CARD_SCALE, CARD_MOVE_SPEED)
	best_card.get_node("AnimationPlayer").play("card_flip")
	
	# Remove card from enemy's hand
	opponent_deck.remove_card_from_hand(best_card)
	
	# Wait for tween to finish before updating hand positions
	await tween.finished  
	$"../EnemyHand".update_hand_positions(CARD_MOVE_SPEED)  # Now the hand updates correctly
	
	best_card.card_slot_card_is_in = slot
	opponent_cards_on_battlefield.append(best_card)
	$"../AudioManager/cardPlaceSFX".play()
	await wait(1.0)


func check_for_usuable_cards():
	for card in $"../PlayerHand".player_hand:
		if card.ammo_req > player_ammo: # unusuable cards
			card.get_node("CardImage").self_modulate = Color(0.2, 0.2, 0.2, 1)
			card.get_node("CardBackImage").self_modulate = Color(0.2, 0.2, 0.2, 1)
		else: # usable cards
			card.get_node("CardImage").self_modulate = Color(1, 1, 1, 1)
			card.get_node("CardBackImage").self_modulate = Color(1, 1, 1, 1)

func play_attack_animation(attacker, card) -> void:
	var object
	var rebound: int = 180
	
	if card.card_name == "Shotgun":
		rebound = 270
		object = $"../CanvasLayer/Shotgun"
	elif card.card_name == "Rifle":
		rebound = 180
		object = $"../CanvasLayer/Rifle"
	elif card.card_name == "Pistol":
		rebound = 90
		object = $"../CanvasLayer/Pistol"
	
	var fadeInTween = get_tree().create_tween()
	fadeInTween.set_ease(Tween.EASE_IN_OUT)
	fadeInTween.set_trans(Tween.TRANS_QUAD)
	fadeInTween.tween_property(object, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	
	var fadeInDarkenerTween = get_tree().create_tween()
	fadeInDarkenerTween.set_ease(Tween.EASE_IN_OUT)
	fadeInDarkenerTween.set_trans(Tween.TRANS_QUAD)
	fadeInDarkenerTween.tween_property($"../CanvasLayer/Darkener", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	if attacker == "Player":
		var rotateLeft = get_tree().create_tween()
		rotateLeft.set_ease(Tween.EASE_IN_OUT)
		rotateLeft.set_trans(Tween.TRANS_QUAD)
		rotateLeft.tween_property(object, "rotation", deg_to_rad(-90), 0.6)
		
		await rotateLeft.finished # about 0.8 seconds
		
		var knockBack = get_tree().create_tween()
		knockBack.set_ease(Tween.EASE_IN_OUT)
		knockBack.set_trans(Tween.TRANS_QUAD)
		knockBack.tween_property(object, "position", Vector2(object.position.x, object.position.y + rebound), 0.1)
		
		await knockBack.finished
		
		var knockBackR = get_tree().create_tween()
		knockBackR.set_ease(Tween.EASE_IN_OUT)
		knockBackR.set_trans(Tween.TRANS_QUAD)
		knockBackR.tween_property(object, "position", Vector2(object.position.x, object.position.y - rebound), 0.8)
	else:
		var rotateRight = get_tree().create_tween()
		rotateRight.set_ease(Tween.EASE_IN_OUT)
		rotateRight.set_trans(Tween.TRANS_QUAD)
		rotateRight.tween_property(object, "rotation", deg_to_rad(90), 0.6)
		
		await rotateRight.finished # about 0.8 seconds
		
		var knockBack = get_tree().create_tween()
		knockBack.set_ease(Tween.EASE_IN_OUT)
		knockBack.set_trans(Tween.TRANS_QUAD)
		knockBack.tween_property(object, "position", Vector2(object.position.x, object.position.y - rebound), 0.1)
		
		await knockBack.finished
		
		var knockBackR = get_tree().create_tween()
		knockBackR.set_ease(Tween.EASE_IN_OUT)
		knockBackR.set_trans(Tween.TRANS_QUAD)
		knockBackR.tween_property(object, "position", Vector2(object.position.x, object.position.y + rebound), 0.8)
	
	var fadeOutTween = get_tree().create_tween()
	fadeOutTween.set_ease(Tween.EASE_IN_OUT)
	fadeOutTween.set_trans(Tween.TRANS_QUAD)
	fadeOutTween.tween_property(object, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
	
	var fadeOutDarkenerTween = get_tree().create_tween()
	fadeOutDarkenerTween.set_ease(Tween.EASE_IN_OUT)
	fadeOutDarkenerTween.set_trans(Tween.TRANS_QUAD)
	fadeOutDarkenerTween.tween_property($"../CanvasLayer/Darkener", "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
	
	await get_tree().create_timer(0.5).timeout

func end_opponent_turn() -> void:
	$"../Deck".reset_draw()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
	
	DiscordRPC.state = "Idle"
	DiscordRPC.refresh()

func update_ammo_display():
	
	# Ensure there are enough ammo icons
	while ammo_container.get_child_count() < player_max_ammo:
		var new_ammo_icon = ammo_icons[0].duplicate()  # Duplicate the first icon
		ammo_container.add_child(new_ammo_icon)
		ammo_icons.append(new_ammo_icon)

	# Update the display
	for i in range(player_max_ammo):
		if i < player_ammo:
			await tween_icon(ammo_icons[i], Color(1, 1, 1, 1), 0.2)
		else:
			await tween_icon(ammo_icons[i], Color(0.2, 0.2, 0.2, 1), 0.2)

func update_enemy_ammo_display():
	for i in range(max_ammo):
		if i < opponent_ammo:
			await tween_icon(opp_ammo_icons[i], Color(1, 1, 1, 1), 0.2)
		else:
			await tween_icon(opp_ammo_icons[i], Color(0.2, 0.2, 0.2, 1), 0.2)

# Separate function to handle tweening
func tween_icon(icon, target_color, seconds):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(icon, "modulate", target_color, seconds)
	await tween.finished

func add_ammo(amount: int, who):
	if who == "Player":
		player_ammo = min(player_ammo + amount, player_max_ammo)
		update_ammo_display()
	elif who == "Opponent":
		opponent_ammo = min(opponent_ammo + amount, max_ammo)
		update_enemy_ammo_display()

func destroy_card(card, card_owner) -> void:
	if card_owner == "Player":
		player_cards_on_battlefield.erase(card)
	else:
		opponent_cards_on_battlefield.erase(card)
		empty_weapon_card_slots.append(card.card_slot_card_is_in)
	
	card.card_slot_card_is_in.card_in_slot = false
	card.queue_free()

func game_over():
	game_ended = true
	
	$"../MatchUI/HealthBar".texture_under = load("res://assets/images/health-bar-nofill-dead.png")
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
	
	var cards_xp_deduction = float(max(1.0, float(ammo_cards_used) / 8.0) + max(1.0, float(attack_cards_used) / 4.0))
	var safe_turns = max(1, turns)  # Prevent division by zero
	
	var xp_gained_full = max(0.0, BASE_XP + float(XP_AMOUNT) / cards_xp_deduction + (TURN_BONUS * (10 - safe_turns)) - (SKIP_PENALTY_FACTOR * skipped_turns * XP_AMOUNT))
	xp_gained_full /= pow(ROUND_PENALTY_FACTOR, safe_turns)  # Apply round penalty
	
	var xp_gained = max(0.0, xp_gained_full / 2)
	
	await tween_label_number($"../DeathUI/XP", 0, xp_gained_full, 2.0)
	await wait(0.5)
	await tween_label_number($"../DeathUI/XP", xp_gained_full, xp_gained, 1.0)
	
	Global.XP += xp_gained
	Global.save_data()

func win():
	game_ended = true
	
	DiscordRPC.state = "Won Game! 👑"
	
	$"../AudioManager/gameOverSFX".play()
	var winDarkenerFadeIn = create_tween()
	winDarkenerFadeIn.set_ease(Tween.EASE_IN_OUT)
	winDarkenerFadeIn.set_trans(Tween.TRANS_QUAD)
	winDarkenerFadeIn.tween_property($"../WinUI/Darkener", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	await winDarkenerFadeIn.finished
	
	var crownFadeIn = create_tween()
	crownFadeIn.set_ease(Tween.EASE_IN_OUT)
	crownFadeIn.set_trans(Tween.TRANS_QUAD)
	crownFadeIn.tween_property($"../WinUI/Crown", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	await crownFadeIn.finished
	await $"../AudioManager/gameOverSFX".finished
	
	var crownFadeOut = create_tween()
	crownFadeOut.set_ease(Tween.EASE_IN_OUT)
	crownFadeOut.set_trans(Tween.TRANS_QUAD)
	crownFadeOut.tween_property($"../WinUI/Crown", "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
	await crownFadeOut.finished
	
	var textFadeIn = create_tween()
	textFadeIn.set_ease(Tween.EASE_IN_OUT)
	textFadeIn.set_trans(Tween.TRANS_QUAD)
	textFadeIn.tween_property($"../WinUI/XP", "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	await textFadeIn.finished
	
	var cards_xp_deduction = float(max(1.0, float(ammo_cards_used) / 8.0) + max(1.0, float(attack_cards_used) / 4.0))
	var safe_turns = max(1, turns)  # Prevent division by zero
	
	var xp_gained = max(0.0, BASE_XP + float(XP_AMOUNT) / cards_xp_deduction + (TURN_BONUS * (10 - safe_turns)) - (SKIP_PENALTY_FACTOR * skipped_turns * XP_AMOUNT))
	xp_gained /= pow(ROUND_PENALTY_FACTOR, safe_turns)  # Apply round penalty
	
	await tween_label_number($"../WinUI/XP", 0, xp_gained, 2.0)
	
	Global.XP += xp_gained
	Global.save_data()

func calculate_xp() -> float:
	var xp_deduction = max(1.0, float(ammo_cards_used) / 8.0 + float(attack_cards_used) / 4.0)
	var xp_gained = max(0.0, BASE_XP + float(XP_AMOUNT) / xp_deduction + (TURN_BONUS * (10 - max(1, turns))) - (SKIP_PENALTY_FACTOR * skipped_turns * XP_AMOUNT))
	xp_gained /= pow(ROUND_PENALTY_FACTOR, max(1, turns))  # Apply round penalty
	return xp_gained

func tween_label_number(label: Label, start_value: int, end_value: int, duration: float):
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(update_label_text.bind(label), start_value, end_value, duration)
	await tween.finished

func update_label_text(value: float, label: Label):
	label.text = str(int(value)) + " XP"
