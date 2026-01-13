extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SoundManager.stop_level_music()
	SoundManager.play_menu_music()

func _on_button_pressed() -> void:
	SoundManager.play_button_sound()
	get_tree().change_scene_to_file("res://menu_title.tscn")
