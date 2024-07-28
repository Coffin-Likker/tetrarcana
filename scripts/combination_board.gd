extends Control

signal combination_complete(combined_piece)

@onready var combination_map = $CombinationMap

var target_position: Vector2
var start_position: Vector2
var animation_duration = 0.5

func _ready():
	hide_board()

	#start_position = Vector2(0, get_viewport_rect().size.y)
	#target_position = Vector2(0, get_viewport_rect().size.y - size.y)
	#position = start_position
	combination_map.connect("combination_complete", Callable(self, "_on_combination_complete"))

func show_board():
	show()
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, animation_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func hide_board():
	hide()
	var tween = create_tween()
	tween.tween_property(self, "position", start_position, animation_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func _on_combination_complete(combined_piece):
	emit_signal("combination_complete", combined_piece)
	hide_board()
