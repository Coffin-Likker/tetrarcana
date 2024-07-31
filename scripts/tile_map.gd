extends TileMap

const TILESET_SOURCE_ID = 0  # Make sure this matches your tileset source ID

const PLAYER_1_TILE = Vector2i(0, 0)
const PLAYER_2_TILE = Vector2i(2, 0)  # Red tile
const EMPTY_TILE = Vector2i(4, 0)
const GHOST_TILE = Vector2i(1, 0)
const GHOST_TILE_OPPONENT = Vector2i(3, 0)
const INVALID_GHOST_TILE = Vector2i(1, 1)
const INVALID_GHOST_TILE_PLAYER_2 = Vector2i(3, 1) 

# Layer constants
const BOARD_LAYER = 0
const GHOST_LAYER = 1
const GHOST_LAYER_Z_INDEX = 1

enum Player { PLAYER_1, PLAYER_2 }
enum GameState { MENU, PLACING, GAME_OVER }

var current_ghost_position = Vector2i(0, 0)
var active_piece = []

signal piece_placed

var board_rect: Rect2i

var is_mouse_over_board = false

@onready var sound_manager = get_node("../GameSoundManager")

var move_cooldown = 0.1  # Time in seconds between moves when key is held
var move_timers = {}

const MOVE_DIRECTIONS = {
	"ui_left": Vector2i(-1, 0),
	"ui_right": Vector2i(1, 0),
	"ui_down": Vector2i(0, 1),
	"ui_up": Vector2i(0, -1)
}

func play_placing_sound():
	var sound = "shadow" if get_parent().current_player == Player.PLAYER_1 else "light"
	sound_manager.play_place_sound(sound)
	
func initialize_move_timers():
	for action in MOVE_DIRECTIONS.keys():
		move_timers[action] = 0.0

func set_active_piece(piece):
	clear_ghost_piece()
	#var local_position = get_local_mouse_position()
	#var map_position = local_to_map(local_position)
	active_piece = piece
	current_ghost_position = Vector2i(board_rect.position.x + board_rect.size.x / 2, board_rect.position.y + board_rect.size.y / 2)
	update_ghost_piece(current_ghost_position)
	print_debug("Active piece set: ", active_piece)

func _ready():
	InputMap.load_from_project_settings()
	print_debug("TileMap initialized. Ready to process input.")
	
	initialize_move_timers()
	set_process_unhandled_input(true)
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)
	
	set_layer_z_index(GHOST_LAYER, GHOST_LAYER_Z_INDEX)
	
	board_rect = get_used_rect()
	current_ghost_position = Vector2i(board_rect.position.x + board_rect.size.x / 2, board_rect.position.y + board_rect.size.y / 2)

func reset():
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	print_debug("Resetting the game board")

	# Clear both layers of the TileMap
	var board_size = get_used_rect().size
	for x in range(board_size.x):
		for y in range(board_size.y):
			var cell_pos = Vector2i(x, y)
			var cell_atlas_coords = get_cell_atlas_coords(BOARD_LAYER, cell_pos)
			if cell_atlas_coords != EMPTY_TILE:
				set_cell(BOARD_LAYER, cell_pos, TILESET_SOURCE_ID, EMPTY_TILE)
	
	# Create starting columns for each player
	# TODO: Would be nice to have these fill out one-by-one with a sound.
	for y in range(board_size.y):
		var player_1_cell_pos = Vector2i(0, y)
		set_cell(BOARD_LAYER, player_1_cell_pos, TILESET_SOURCE_ID, PLAYER_1_TILE)

		var player_2_cell_pos = Vector2i(board_size.x - 1, y)
		set_cell(BOARD_LAYER, player_2_cell_pos, TILESET_SOURCE_ID, PLAYER_2_TILE)

	clear_layer(GHOST_LAYER)

	# Reset game-specific variables
	current_ghost_position = Vector2i(0, 0)
	active_piece = []

	# Ensure there are at least two layers (BOARD_LAYER and GHOST_LAYER)
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)

	# Update the ghost piece to reflect the new active piece
	update_ghost_piece(map_position)

	print_debug("Game board reset complete")

func play_move_sound():
	sound_manager.play_move_sound()

func _input(event):
	if get_parent().game_state != get_parent().GameState.PLACING:
		clear_ghost_piece()
		return

	if event is InputEventMouseMotion:
		var local_position = get_local_mouse_position()
		var map_position = local_to_map(local_position)
		if get_used_rect().has_point(map_position):
			update_ghost_piece(map_position)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position = get_local_mouse_position()
		var map_position = local_to_map(click_position)
		if get_used_rect().has_point(map_position):
			_on_tile_clicked(map_position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		rotate_piece(1)
	elif event is InputEventKey and event.pressed:
		handle_keyboard_input(event.keycode)


func handle_keyboard_input(keycode):
	match keycode:
		KEY_LEFT:
			move_piece(Vector2i(-1, 0))
		KEY_RIGHT:
			move_piece(Vector2i(1, 0))
		KEY_UP:
			move_piece(Vector2i(0, -1))
		KEY_DOWN:
			move_piece(Vector2i(0, 1))
		KEY_ENTER:
			_on_tile_clicked(current_ghost_position)
		KEY_R:
			rotate_piece(1)

func move_piece(direction: Vector2i):
	var new_position = current_ghost_position + direction
	if is_valid_position(new_position):
		current_ghost_position = new_position
		update_ghost_piece(current_ghost_position)

#FIX ROTATION BY COPYING IT IDENTICALLY FROM COMBINATION BOARD
func _process(delta):
	if get_parent().game_state != get_parent().GameState.PLACING:
		return
	if Input.is_action_just_pressed("rotate_clockwise"):
		rotate_piece(1)
#	elif Input.is_action_just_pressed("rotate_counterclockwise"):
#		rotate_piece(-1)
	update_ghost_piece_position()

func update_ghost_piece_position():
	var game_manager = get_parent()
	if game_manager.game_state != game_manager.GameState.PLACING:
		clear_ghost_piece()
		return

	var mouse_position = get_global_mouse_position()
	var map_position = local_to_map(to_local(mouse_position))

	# Clamp the position to the board boundaries
	map_position.x = clamp(map_position.x, board_rect.position.x, board_rect.end.x - 1)
	map_position.y = clamp(map_position.y, board_rect.position.y, board_rect.end.y - 1)

	if map_position != current_ghost_position:
		current_ghost_position = map_position
		update_ghost_piece(current_ghost_position)

func _unhandled_input(event):
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	var game_manager = get_parent()
	if event is InputEventMouseMotion and  game_manager.game_state == GameState.PLACING:
		if is_valid_position(map_position):
			update_ghost_piece(map_position)

func _on_tile_clicked(map_position: Vector2i):	
	var game_manager = get_parent()
	var player_tile = PLAYER_1_TILE if game_manager.current_player == Player.PLAYER_1 else PLAYER_2_TILE
	place_piece(map_position, player_tile)

func place_piece(map_position: Vector2i, tile: Vector2i):
	var game_manager = get_parent()
	print_debug("Placing piece at base position: ", map_position)
	
	if not is_valid_position(map_position):
		sound_manager.play_cant_place_sound()
		print_debug("Invalid placement: out of bounds")
		return
	
	if can_place_piece(map_position, tile):
		for offset in active_piece:
			var tile_position = map_position + offset
			set_cell(BOARD_LAYER, tile_position, TILESET_SOURCE_ID, tile)
		clear_ghost_piece()  # Clear the ghost piece after placing
		play_placing_sound()
		emit_signal("piece_placed")
	else:
		sound_manager.play_cant_place_sound()  # Add this line
		print_debug("Invalid placement")

func can_place_piece(map_position: Vector2i, tile: Vector2i) -> bool:
	var overlaps_own_color = false
	for offset in active_piece:
		var tile_position = map_position + offset
		var existing_tile = get_cell_atlas_coords(BOARD_LAYER, tile_position)
		if existing_tile == tile:
			overlaps_own_color = true
			break
	return overlaps_own_color

func update_ghost_piece(map_position: Vector2i):
	clear_layer(GHOST_LAYER)
	var game_manager = get_parent()
	if game_manager.game_state != game_manager.GameState.PLACING:
		clear_ghost_piece()
		return

	if active_piece.is_empty():
		return

	if map_position != current_ghost_position:
		current_ghost_position = map_position

	var current_player_tile = PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else PLAYER_2_TILE
	var ghost_tile 

	var can_place = get_parent().game_state == get_parent().GameState.PLACING and can_place_piece(current_ghost_position, current_player_tile)

	if game_manager.current_player == game_manager.Player.PLAYER_1:
		ghost_tile = GHOST_TILE if can_place else INVALID_GHOST_TILE
	else:
		ghost_tile = GHOST_TILE_OPPONENT if can_place else INVALID_GHOST_TILE_PLAYER_2

	for offset in active_piece:
		var tile_position = map_position + offset
		if get_used_rect().has_point(tile_position):
			set_cell(GHOST_LAYER, tile_position, TILESET_SOURCE_ID, ghost_tile)

func rotate_piece(direction: int):
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	if can_rotate():
		# Create a rotation matrix for 90 degrees rotation (clockwise or counterclockwise)
		var rotation_matrix = Transform2D().rotated(direction * PI/2)
		var new_piece = []
		# Rotate each block of the active piece
		for block in active_piece:
			# Apply rotation matrix to the block
			var rotated_position = rotation_matrix * Vector2(block)
			# Round and store the rotated position
			new_piece.append(Vector2i(round(rotated_position.x), round(rotated_position.y)))
		
		# Calculate offset to keep the rotated piece in the same general area
		var min_x = active_piece[0].x
		var min_y = active_piece[0].y
		var rotated_min_x = new_piece[0].x
		var rotated_min_y = new_piece[0].y
		
		for block in active_piece:
			min_x = min(min_x, block.x)
			min_y = min(min_y, block.y)
		
		for block in new_piece:
			rotated_min_x = min(rotated_min_x, block.x)
			rotated_min_y = min(rotated_min_y, block.y)

		# Calculate the offset
		var offset = Vector2i(min_x - rotated_min_x, min_y - rotated_min_y)

		# Apply the offset to each block of the new piece
		active_piece = new_piece.map(func(block): return block + offset)
		sound_manager.play_rotate_sound()
		update_ghost_piece(map_position)

func can_rotate():
	return true
	
func update_for_new_turn(new_player: Player):
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	clear_ghost_piece()  # Clear the ghost piece at the start of a new turn
	update_ghost_piece(map_position)
	
func clear_ghost_piece():
	clear_layer(GHOST_LAYER)

func is_valid_position(position: Vector2i) -> bool:
	for offset in active_piece:
		var tile_position = position + offset
		if not get_used_rect().has_point(tile_position):
			return false
	return true
