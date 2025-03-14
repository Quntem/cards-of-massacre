extends Node2D

const CARD_SCENE_PATH = "res://assets/scenes/subscene/enemy_card.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTER_HAND_SIZE = 4

var opponent_deck: Array = ["shotgun-card", "shotgun-card", "shotgun-card", "ammo-card-1", "ammo-card-2", "ammo-card-2"]
var card_database_reference

func _ready() -> void:
	opponent_deck.shuffle()
	card_database_reference = preload("res://assets/scripts/card_database.gd")
	for i in range(STARTER_HAND_SIZE):
		draw_card()

func draw_card():
	var card_drawn_name = opponent_deck[0]
	opponent_deck.erase(card_drawn_name)
	
	$"../AudioManager/cardSwipeSFX".play()
	
	if opponent_deck.size() == 0:
		$Sprite2D.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://assets/images/" + card_drawn_name + ".png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.damage = card_database_reference.CARDS[card_drawn_name][0]
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][3]
	
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	new_card.scale = Vector2(1.5, 1.5)
	$"../EnemyHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
