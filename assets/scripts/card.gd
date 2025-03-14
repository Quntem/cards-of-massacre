extends Node2D

signal hovered
signal hovered_off

var hand_position
var card_slot_card_is_in
var card_type
var damage

func _ready() -> void:
	get_parent().connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
