extends Node


@onready var main_menu: Control = $MainMenu
@onready var options_menu: Control = $OptionsMenu
@onready var bg_music: AudioStreamPlayer2D = $MenuMusic


var current_menu: Control = null


func _ready():
	# Hide all menus initially.
	main_menu.hide()
	options_menu.hide()
	
	change_menu(main_menu)


func change_menu(menu: Control):
	if current_menu:
		current_menu.hide()
	menu.show()
	current_menu = menu


func set_music_volume(value: float):
	bg_music.volume_db = linear_to_db(value)


func _on_main_menu_quit_game():
	get_tree().quit()


func _on_options_menu_go_back():
	change_menu(main_menu)


func _on_main_menu_show_options():
	change_menu(options_menu)


func _on_main_menu_start_game():
	pass # Replace with function body.
