extends Container
class_name menu_manager

signal game_started
signal go_main_menu

@onready var splash_screen = $"../SplashScreen"
@onready var main_menu: Control = $MainMenu
@onready var options_menu: Control = $OptionsMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var bg_music: AudioStreamPlayer2D = $MenuMusic
@onready var focus_sounds: Array[AudioStreamPlayer] = [
	$FocusSound,
	$FocusSound2,
	$FocusSound3,
	$FocusSound4,
	$FocusSound5,
	$FocusSound6,
	$FocusSound7,
	$FocusSound8,
	$FocusSound9,
	$FocusSound10
]

var current_menu: Control = null
var current_sound_index: int = 0

func _ready():
	# Hide all menus initially.
	splash_screen.connect("go_main_menu", Callable(self, "show_main_menu"))
	main_menu.hide()
	options_menu.hide()
	game_over_menu.hide()
	change_menu(main_menu)
	connect_focus_signals(self)
	
	setup_looping_navigation($MainMenu/VBoxContainer)
	setup_looping_navigation($OptionsMenu/OptionsVBox)
	setup_looping_navigation($GameOverMenu/VBoxContainer)

func show_main_menu():
	change_menu(main_menu)
	start_menu_music()

func change_menu(menu: Control):
	if current_menu:
		current_menu.hide()
	menu.show()
	current_menu = menu
	focus_first_control(menu)
	start_menu_music()

func focus_first_control(node: Node):
	var focusable_controls = get_focusable_controls(node)
	if focusable_controls.size() > 0:
		focusable_controls[0].grab_focus()
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
	stop_menu_music()
	emit_signal("game_started")

func _on_game_over_go_main_menu():
	game_over_menu.hide()
	change_menu(main_menu)
	emit_signal("go_main_menu")

func _on_game_over_restart_game():
	main_menu.hide()
	options_menu.hide()
	game_over_menu.hide()
	stop_menu_music()
	emit_signal("game_started")

func on_control_focus_entered():
	focus_sounds[current_sound_index].play()
	current_sound_index = (current_sound_index + 1) % focus_sounds.size()

func connect_focus_signals(node: Node):
	if node is Button or node is Slider:
		if not node.is_connected("focus_entered", Callable(self, "on_control_focus_entered")):
			node.connect("focus_entered", Callable(self, "on_control_focus_entered"))
	for child in node.get_children():
		connect_focus_signals(child)

func setup_looping_navigation(menu: Control):
	var focusable_controls = get_focusable_controls(menu)
	if focusable_controls.size() < 2:
		return
	var first_control = focusable_controls[0]
	var last_control = focusable_controls[-1]
	# Set up looping for the first and last controls
	first_control.focus_neighbor_top = last_control.get_path()
	last_control.focus_neighbor_bottom = first_control.get_path()
	# Set up navigation between adjacent controls
	for i in range(focusable_controls.size()):
		var current = focusable_controls[i]
		var next = focusable_controls[(i + 1) % focusable_controls.size()]
		var prev = focusable_controls[(i - 1 + focusable_controls.size()) % focusable_controls.size()]
		current.focus_neighbor_bottom = next.get_path()
		current.focus_neighbor_top = prev.get_path()

func get_focusable_controls(node: Node) -> Array:
	var focusables = []
	if (node is Button or node is Slider) and node.focus_mode != Control.FOCUS_NONE:
		focusables.append(node)
	for child in node.get_children():
		focusables += get_focusable_controls(child)
	return focusables

func start_menu_music():
	if not bg_music.playing:
		bg_music.play()

func stop_menu_music():
	bg_music.stop()
