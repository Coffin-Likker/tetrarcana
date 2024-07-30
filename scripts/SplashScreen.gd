extends Control

signal go_main_menu 

func _ready():
	$VBoxContainer/TutorialText.text = """
	Welcome to Your Game!
	
	How to play:
	1. Combine pieces on your board
	2. Place the combined piece on the main board
	3. Fill 80% of the board to end the game
	4. The player with the most tiles wins!
	
	Click 'Start Game' to begin!
	"""

func _on_main_menu_button_pressed():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	emit_signal("go_main_menu")
	hide()
