extends Node2D

const CARD_SCENE_PATH = "res://assets/scenes/subscene/card.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTER_HAND_SIZE = 4

var player_deck: Array = ["shotgun-card", "shotgun-card", "shotgun-card", "ammo-card-1", "ammo-card-2", "ammo-card-2"]
var card_database_reference
var drawn_card_this_turn: bool = false

func _ready() -> void:
	player_deck.shuffle()
	card_database_reference = preload("res://assets/scripts/card_database.gd")
	for i in range(STARTER_HAND_SIZE):
		drawn_card_this_turn = false
		draw_card()
		await get_tree().create_timer(.2).timeout
	drawn_card_this_turn = true

func draw_card():
	if drawn_card_this_turn:
		return
	
	drawn_card_this_turn = true
	
	var card_drawn_name = player_deck[0]
	player_deck.erase(card_drawn_name)
	
	$"../AudioManager/cardSwipeSFX".play()
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://assets/images/" + card_drawn_name + ".png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][3]
	new_card.damage = card_database_reference.CARDS[card_drawn_name][0]
	
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	new_card.scale = Vector2(1.5, 1.5)
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

func reset_draw():
	drawn_card_this_turn = false
