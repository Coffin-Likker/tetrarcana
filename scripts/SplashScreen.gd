extends Control

signal go_main_menu 

func _ready():
	$VBoxContainer/TutorialText.text = """
	Welcome to TETRARCANA!
	This is a turn based local 1v1 territory battle game.
	Grab a friend and enjoy!
	How to play:
	Tetrarcana is all about combining tetrominoes by
	overlapping their tiles.

	1. Place pieces with left click, rotate with right click.

	2. Combine two pieces on your scroll by placing the first
	and then overlapping at least one tile with the second

	3. Place the combined piece on the main board by
	overlapping one of your colour's tiles

	4. Fill 90% of the board to end the game (keep an eye on 
	the potions to see how far along you are)

	5. The player with the most tiles wins!
	
	Click 'Start Game' to begin!
	"""

func _on_main_menu_button_pressed():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	emit_signal("go_main_menu")
	hide()
