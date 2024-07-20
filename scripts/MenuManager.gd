extends Node

var menus = {
	MenuTypes.Type.MAIN: preload("res://scenes/menus/MainMenu.tscn"),
	MenuTypes.Type.OPTIONS: preload("res://scenes/menus/OptionsMenu.tscn"),	
}

var current_menu: Control = null
var menu_stack: Array[MenuTypes.Type] = []

@onready var bg_music: AudioStreamPlayer2D = $MenuMusic

func _ready():
	change_menu(MenuTypes.Type.MAIN)

func change_menu(menu_type:	 MenuTypes.Type):
	if current_menu:
		current_menu.queue_free()
	
	var new_menu = menus[menu_type].instantiate()
	add_child(new_menu)
	current_menu = new_menu
	
	# Connect signals
	if new_menu.has_signal("menu_changed"):
		new_menu.connect("menu_changed", Callable(self, "_on_menu_changed"))
	if new_menu.has_signal("menu_back"):
		new_menu.connect("menu_back", Callable(self, "_on_menu_back"))

func push_menu(menu_type: MenuTypes.Type):
	menu_stack.push_back(menu_type)
	change_menu(menu_type)

func pop_menu():
	if menu_stack.size() > 1:  # Always keep at least the main menu
		menu_stack.pop_back()
		change_menu(menu_stack.back())

func _on_menu_changed(new_menu_type: MenuTypes.Type):
	push_menu(new_menu_type)

func _on_menu_back():
	pop_menu()

func set_music_volume(value: float):
	bg_music.volume_db = linear_to_db(value)
