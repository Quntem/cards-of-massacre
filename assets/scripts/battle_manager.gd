extends Node

const SMALL_CARD_SCALE = 1.45
const CARD_MOVE_SPEED = 0.2

var battle_timer
var empty_monster_card_slots = []

func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot")

func _on_end_turn_button_pressed() -> void:
	opponent_turn()

func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	battle_timer.start()
	await battle_timer.timeout
	
	if $"../EnemyDeck".opponent_deck.size() != 0:
		$"../EnemyDeck".draw_card()
		battle_timer.start()
		await battle_timer.timeout
	
	if empty_monster_card_slots.size() == 0:
		end_opponent_turn()
		return
	
	await try_play_card()
	
	end_opponent_turn()

func try_play_card():
	var enemy_hand = $"../EnemyHand".enemy_hand
	if enemy_hand.size() == 0:
		end_opponent_turn()
		return
	
	var random_empty_monster_card_slot = empty_monster_card_slots[0]
	empty_monster_card_slots.erase(random_empty_monster_card_slot)
	
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
	
	battle_timer.start()
	await battle_timer.timeout


func end_opponent_turn():
	# $"../PlayerHand".reset_draw()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
