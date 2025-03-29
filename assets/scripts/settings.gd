extends Node

@onready var volume_label: Label = $MarginContainer/VBoxContainer/VolumeLabel
@onready var volume: HSlider = $MarginContainer/VBoxContainer/Volume
@onready var absolute_db_checkbox: CheckBox = $MarginContainer/VBoxContainer/AbsoluteDBCheckbox
@onready var very_precise_checkbox: CheckBox = $MarginContainer/VBoxContainer/VeryPreciseCheckbox

func _ready() -> void:
	AudioManager.update_volume()
	
	absolute_db_checkbox.button_pressed = Global.absolute_db
	very_precise_checkbox.button_pressed = Global.very_precise
	volume.value = -Global.volume
	
	if absolute_db_checkbox.button_pressed == false:
		very_precise_checkbox.disabled = true
		very_precise_checkbox.visible = false

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, -value)
	Global.volume = -value
	Global.save_data()
	update_volume_label()

func update_volume_label():
	if !Global.absolute_db:
		volume_label.text = str(convert_db_to_percentage(AudioServer.get_bus_volume_db(0))) + "%"
	else:
		if !Global.very_precise:
			volume_label.text = str(snapped(AudioServer.get_bus_volume_db(0), 0.01)) + " DB"
		else:
			volume_label.text = str(AudioServer.get_bus_volume_db(0), 0.000001) + " DB"

func _on_volume_drag_ended(value_changed: bool) -> void:
	$AudioManager/volumeAdjustSFX.play()

func convert_db_to_percentage(db_level: float) -> int:
	var min_db = -35.0
	var max_db = 0.0
	var percentage = ((db_level - min_db) / (max_db - min_db)) * 100.0
	return int(percentage)

func _on_absolute_db_checkbox_toggled(toggled_on: bool) -> void:
	Global.absolute_db = toggled_on
	Global.save_data()
	update_volume_label()
	
	if toggled_on == false:
		very_precise_checkbox.disabled = true
		very_precise_checkbox.visible = false
	else:
		very_precise_checkbox.disabled = false
		very_precise_checkbox.visible = true

func _on_very_precise_checkbox_toggled(toggled_on: bool) -> void:
	Global.very_precise = toggled_on
	Global.save_data()
	update_volume_label()
