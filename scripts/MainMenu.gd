extends "res://scripts/BaseMenu.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/Start.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/game_manager.tscn")


func _on_options_pressed():
	change_menu(MenuTypes.Type.OPTIONS)


func _on_quit_to_desktop_pressed():
	get_tree().quit()
