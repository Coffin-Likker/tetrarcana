extends Control


signal start_game
signal start_single_player_game
signal show_options
signal quit_game


func _on_start_pressed():
	start_game.emit()


func _on_options_pressed():
	show_options.emit()


func _on_quit_to_desktop_pressed():
	quit_game.emit()


func _on_single_player_pressed():
	start_single_player_game.emit()
