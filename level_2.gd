extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_level_music()
	Global.coins = 0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_fall_zone_body_entered(body: Node3D) -> void:
	SoundManager.play_fall_sound()
	get_tree().change_scene_to_file("res://menu_game_over.tscn")
