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
var active_piece: Array[Vector2i] = []

signal piece_placed

var board_rect: Rect2i

var is_mouse_over_board = false

@onready var sound_manager = get_node("../GameSoundManager")
@onready var input_manager = get_node("../InputManager")

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


func set_active_piece(piece: Array[Vector2i]):
	active_piece = piece
	current_ghost_position = Vector2i(
		board_rect.position.x + board_rect.size.x / 2, board_rect.position.y + board_rect.size.y / 2
	)
	update_ghost_piece(current_ghost_position)
	print_debug("Active piece set: ", active_piece)


func _ready():
	InputMap.load_from_project_settings()
	print_debug("TileMap initialized. Ready to process input.")
	input_manager.connect("move_piece", Callable(self, "_on_move_piece"))
	input_manager.connect("rotate_piece", Callable(self, "_on_rotate_piece"))
	input_manager.connect("place_piece", Callable(self, "_on_place_piece"))

	initialize_move_timers()
	set_process_unhandled_input(true)
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)

	set_layer_z_index(GHOST_LAYER, GHOST_LAYER_Z_INDEX)

	board_rect = get_used_rect()
	current_ghost_position = Vector2i(
		board_rect.position.x + board_rect.size.x / 2, board_rect.position.y + board_rect.size.y / 2
	)
	update_ghost_piece(current_ghost_position)


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
		clear_layer(GHOST_LAYER)
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


func _on_move_piece(direction: Vector2i):
	if get_parent().game_state == get_parent().GameState.PLACING:
		move_piece(direction)

func _on_rotate_piece(clockwise: bool):
	if get_parent().game_state == get_parent().GameState.PLACING:
		set_active_piece(rotate_piece(active_piece, 1 if clockwise else -1))

func _on_place_piece():
	if get_parent().game_state == get_parent().GameState.PLACING:
		_on_tile_clicked(current_ghost_position)

#func handle_keyboard_input(keycode):
	#match keycode:
		#KEY_LEFT:
			#move_piece(Vector2i(-1, 0))
		#KEY_RIGHT:
			#move_piece(Vector2i(1, 0))
		#KEY_UP:
			#move_piece(Vector2i(0, -1))
		#KEY_DOWN:
			#move_piece(Vector2i(0, 1))
		#KEY_ENTER:
			#_on_tile_clicked(current_ghost_position)
		#KEY_R:
			#set_active_piece(rotate_piece(active_piece, 1))


func move_piece(direction: Vector2i):
	var new_position: Vector2i = current_ghost_position + direction
	if is_in_bounds(active_piece, new_position):
		current_ghost_position = new_position
		update_ghost_piece(current_ghost_position)
		play_move_sound()


func _process(_delta):
	if get_parent().game_state != get_parent().GameState.PLACING:
		return
	update_ghost_piece(current_ghost_position)

func _on_tile_clicked(map_position: Vector2i) -> void:
	var game_manager = get_parent()
	var player_tile: Vector2i = (
		PLAYER_1_TILE if game_manager.current_player == Player.PLAYER_1 else PLAYER_2_TILE
	)
	place_piece(active_piece, map_position, player_tile)


func place_piece(piece: Array[Vector2i], map_position: Vector2i, tile: Vector2i) -> void:
	print_debug("Attempting to place piece at position %v" % map_position)

	if not can_place_piece(piece, map_position, tile):
		sound_manager.play_cant_place_sound()
		return

	for offset in piece:
		var tile_position: Vector2i = map_position + offset
		set_cell(BOARD_LAYER, tile_position, TILESET_SOURCE_ID, tile)
	clear_layer(GHOST_LAYER)
	play_placing_sound()
	emit_signal("piece_placed")


## Checks that the `piece` placed at this `map_position` would not go out of bounds and would overlap with the
## player's own colour.
func can_place_piece(
	piece: Array[Vector2i], map_position: Vector2i, player_tile: Vector2i, layer: int = BOARD_LAYER
) -> bool:
	return (
		is_in_bounds(piece, map_position)
		and piece_overlaps(piece, map_position, player_tile, layer)
	)


## Checks if all positions of the piece are within the game board bounds.
func is_in_bounds(piece: Array[Vector2i], map_position: Vector2i) -> bool:
	return not calculate_piece_positions(piece, map_position).any(
		func(piece_position: Vector2i) -> bool: return not get_used_rect().has_point(piece_position)
	)


## Checks if a piece overlaps with any existing tiles of the player.
func piece_overlaps(
	piece: Array[Vector2i], map_position: Vector2i, player_tile: Vector2i, layer: int = BOARD_LAYER
) -> bool:
	return calculate_piece_positions(piece, map_position).any(
		func(piece_position: Vector2i) -> bool: return (
			get_cell_atlas_coords(layer, piece_position) == player_tile
		)
	)


## Calculates all tile positions a piece would occupy.
func calculate_piece_positions(piece: Array[Vector2i], map_position: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for offset in piece:
		positions.append(map_position + offset)
	return positions


func update_ghost_piece(map_position: Vector2i) -> void:
	clear_layer(GHOST_LAYER)
	var game_manager = get_parent()
	if game_manager.game_state != game_manager.GameState.PLACING:
		clear_layer(GHOST_LAYER)
		return

	if active_piece.is_empty():
		return

	if map_position != current_ghost_position:
		current_ghost_position = map_position

	var current_player_tile: Vector2i = (
		PLAYER_1_TILE
		if game_manager.current_player == game_manager.Player.PLAYER_1
		else PLAYER_2_TILE
	)
	var ghost_tile

	var can_place: bool = (
		get_parent().game_state == get_parent().GameState.PLACING
		and can_place_piece(active_piece, current_ghost_position, current_player_tile)
	)

	if game_manager.current_player == game_manager.Player.PLAYER_1:
		ghost_tile = GHOST_TILE if can_place else INVALID_GHOST_TILE
	else:
		ghost_tile = GHOST_TILE_OPPONENT if can_place else INVALID_GHOST_TILE_PLAYER_2

	for offset in active_piece:
		var tile_position: Vector2i = map_position + offset
		if get_used_rect().has_point(tile_position):
			set_cell(GHOST_LAYER, tile_position, TILESET_SOURCE_ID, ghost_tile)


## Return the given `piece_` rotated by `rotation_ * PI/2` around the origin block at `(0, 0)`.
func rotate_piece(piece_: Array[Vector2i], rotation_: int) -> Array[Vector2i]:
	# Calculate sine and cosine for the rotation
	var angle = rotation_ * PI/2
	var cos_theta = cos(angle)
	var sin_theta = sin(angle)

	# Rotate each block
	var rotated_piece: Array[Vector2i] = []
	for block in piece_:
		# Apply rotation matrix manually
		var rotated_x = round(block.x * cos_theta - block.y * sin_theta)
		var rotated_y = round(block.x * sin_theta + block.y * cos_theta)
		
		rotated_piece.append(Vector2i(rotated_x, rotated_y))

	return rotated_piece


func update_for_new_turn(new_player: Player):
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	clear_layer(GHOST_LAYER)
	update_ghost_piece(map_position)
