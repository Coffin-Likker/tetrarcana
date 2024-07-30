extends Node2D

@onready var game_manager = $GameManager
@onready var menu_manager = $MenuManager
@onready var splash_screen = $SplashScreen

func _ready():
	# Mute audio initially
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	
	# Show splash screen
	splash_screen.show()
	
	# Hide game elements
	game_manager.hide()
	menu_manager.hide()
	splash_screen.connect("go_main_menu", Callable(self, "_on_splash_screen_go_main_menu"))


func _on_splash_screen_go_main_menu():
	# Hide splash screen
	splash_screen.hide()
	
	# Show game elements
	game_manager.show()
	menu_manager.show()
	
	# Start the game
	menu_manager.show_main_menu()
