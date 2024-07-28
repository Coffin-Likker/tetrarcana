extends Control

signal restart_game 
signal go_main_menu 

@onready var winner_label = $VBoxContainer/winner_label
@onready var main_menu_button = $VBoxContainer/main_menu_button
@onready var restart_button = $VBoxContainer/restart_button

func _ready():
	hide()

func on_game_over(winner: String):
	winner_label.text = winner
	# Reset the opacity and disable buttons before showing the menu
	modulate.a = 0
	main_menu_button.disabled = true
	restart_button.disabled = true
	show()
	
	# Start the fade-in animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Enable buttons after a delay
	await get_tree().create_timer(0.3).timeout
	main_menu_button.disabled = false
	restart_button.disabled = false

func _on_restart_button_pressed():
	restart_game.emit()

func _on_main_menu_button_pressed():
	go_main_menu.emit()
