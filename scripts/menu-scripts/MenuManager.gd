extends Container

class_name menu_manager
signal game_started
signal go_main_menu

@onready var main_menu: Control = $MainMenu
@onready var options_menu: Control = $OptionsMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var bg_music: AudioStreamPlayer2D = $MenuMusic
@onready var focus_sound: AudioStreamPlayer2D = $FocusSound
@onready var focus_sounds: Array[AudioStreamPlayer2D] = [
	$FocusSound,
	$FocusSound2,
	$FocusSound3,
	$FocusSound4,
	$FocusSound5,
	$FocusSound6,
	$FocusSound7,
	$FocusSound8
]

var current_menu: Control = null
var current_sound_index: int = 0

func _ready():
	# Hide all menus initially.
	main_menu.hide()
	options_menu.hide()
	game_over_menu.hide()
	change_menu(main_menu)
	connect_button_signals(self)
	
	setup_looping_navigation($MainMenu/VBoxContainer)
	setup_looping_navigation($OptionsMenu/OptionsVBox)
	setup_looping_navigation($GameOverMenu/VBoxContainer)


func change_menu(menu: Control):
	if current_menu:
		current_menu.hide()
	menu.show()
	current_menu = menu
	focus_first_button(menu)
	
func focus_first_button(node: Node):
	if node is Button:
		node.grab_focus()
		return true
	for child in node.get_children():
		if focus_first_button(child):
			return true
	return false
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and current_menu != main_menu:
		change_menu(main_menu)


func set_music_volume(value: float):
	bg_music.volume_db = linear_to_db(value)


func _on_main_menu_quit_game():
	get_tree().quit()


func _on_options_menu_go_back():
	change_menu(main_menu)


func _on_main_menu_show_options():
	change_menu(options_menu)

func on_game_over(winner:String):
	game_over_menu.show()
	game_over_menu.on_game_over(winner)

func _on_main_menu_start_game():
	main_menu.hide()
	options_menu.hide()
	game_over_menu.hide()
	emit_signal("game_started")

func _on_game_over_go_main_menu():
	game_over_menu.hide()
	change_menu(main_menu)
	emit_signal("go_main_menu")

func _on_game_over_restart_game():
	main_menu.hide()
	options_menu.hide()
	game_over_menu.hide()
	emit_signal("game_started")

func _on_button_focus_entered():
	focus_sounds[current_sound_index].play()
	current_sound_index = (current_sound_index + 1) % focus_sounds.size()

func connect_button_signals(node: Node):
	if node is Button:
		if not node.is_connected("focus_entered", _on_button_focus_entered):
			node.connect("focus_entered", _on_button_focus_entered)
	for child in node.get_children():
		connect_button_signals(child)

func setup_looping_navigation(container: Container):
	var buttons = []
	for child in container.get_children():
		if child is Button:
			buttons.append(child)
	
	if buttons.size() < 2:
		return  # Not enough buttons to create a loop
	
	var first_button = buttons[0]
	var last_button = buttons[-1]
	
	# Set the "up" focus neighbor of the first button to the last button
	first_button.focus_neighbor_top = last_button.get_path()
	
	# Set the "down" focus neighbor of the last button to the first button
	last_button.focus_neighbor_bottom = first_button.get_path()
