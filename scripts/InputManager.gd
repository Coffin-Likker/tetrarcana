extends Node

signal move_piece(direction: Vector2i)
signal rotate_piece(clockwise: bool)
signal place_piece

var is_keyboard_active = false
var move_cooldown = 0.1  # Time in seconds between moves
var move_timer = 0.0

func _process(delta):
	move_timer += delta
	handle_input()

func handle_input():
	var movement = Vector2i.ZERO
	if Input.is_action_pressed("move_left"):
		movement.x -= 1
	if Input.is_action_pressed("move_right"):
		movement.x += 1
	if Input.is_action_pressed("move_up"):
		movement.y -= 1
	if Input.is_action_pressed("move_down"):
		movement.y += 1
	
	if movement != Vector2i.ZERO and move_timer >= move_cooldown:
		is_keyboard_active = true
		emit_signal("move_piece", movement)
		move_timer = 0.0
	
	if Input.is_action_just_pressed("ui_accept"):
		emit_signal("place_piece")
	
	if Input.is_action_just_pressed("rotate_clockwise"):
		emit_signal("rotate_piece", true)
	
	if Input.is_action_just_pressed("rotate_counterclockwise"):
		emit_signal("rotate_piece", false)

func is_using_keyboard():
	return is_keyboard_active
