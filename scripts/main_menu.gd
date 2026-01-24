extends Control

func _ready():
	$VBox/PlayBtn.pressed.connect(_on_play_btn_pressed)
	$VBox/ExitBtn.pressed.connect(_on_exit_btn_pressed)

func _on_play_btn_pressed():
	# Change to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_exit_btn_pressed():
	get_tree().quit()
