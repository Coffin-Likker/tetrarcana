extends CanvasLayer

class_name ui
signal game_started 
signal restart_game 
signal go_main_menu 

@onready var game_over_screen = $game_over_screen
@onready var main_menu_screen = $main_menu_screen
#@onready var bg_music: AudioStreamPlayer2D = $MenuMusic


func _ready():
	game_over_screen.visible = false
	main_menu_screen.visible = true

func on_game_over(winner:String):
	game_over_screen.visible = true
	$game_over_screen/game_over_display/winner_label.text = winner

func _on_restart_button_pressed():
	main_menu_screen.visible = false
	game_over_screen.visible = false
	emit_signal("restart_game")

func _on_main_menu_button_pressed():
	main_menu_screen.visible = true
	game_over_screen.visible = false
	emit_signal("go_main_menu")
	
func _on_start_button_pressed():
	main_menu_screen.visible = false
	emit_signal("game_started")
	
func _on_quit_button_pressed():
	get_tree().quit()
# To be implement with the new UI structure, be it in the same component or as seperate screens
#func _on_options_pressed():
