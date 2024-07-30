extends Control

signal go_main_menu 

func _ready():
	$VBoxContainer/TutorialText.text = """
	Welcome to TETRARCANA
	This is a turn based local 1v1 territory battle game.
	Grab a friend and enjoy!
	How to play:
	Tetrarcana is all about combining tetrominoes by
	overlapping their tiles.

	1. Combine two pieces on your scroll by placing the first
	and then overlapping at least one tile with the second

	2. Place the combined piece on the main board by
	overlapping one of your colour's tiles

	3. Fill 90% of the board to end the game

	4. The player with the most tiles wins!
	
	Click 'Start Game' to begin!
	"""

func _on_main_menu_button_pressed():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	emit_signal("go_main_menu")
	hide()
