extends Node2D

const CARD_SCENE_PATH = "res://assets/scenes/subscene/card.tscn"
const CARD_DRAW_SPEED = 0.2

var player_deck: Array = ["1Ammo", "1Ammo", "1Ammo"]

func draw_card():
	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	new_card.scale = Vector2(1.5, 1.5)
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
