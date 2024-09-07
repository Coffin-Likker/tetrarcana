extends TileMap

const TILESET_SOURCE_ID = 1  # Make sure this matches your tileset source ID


const PLAYER_1_TILE = Vector2i(0, 0)
const PLAYER_2_TILE = Vector2i(2, 0)  # Red tile
const EMPTY_TILE = Vector2i(4, 0)
const GHOST_TILE = Vector2i(1, 0)
const GHOST_TILE_OPPONENT = Vector2i(3, 0)
const INVALID_GHOST_TILE = Vector2i(1, 1)
const INVALID_GHOST_TILE_PLAYER_2 = Vector2i(3, 1) 


# Board constants
const BOARD_WIDTH = 6
const BOARD_HEIGHT = 6
const BOARD_OFFSET = Vector2i(0, 0)  # Adjust this if your board isn't at (0,0)


const ALL_SHAPES = [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)],  # S_SHAPE
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],  # I_SHAPE
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],  # L_Shape
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1)], # J_Shape
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],  # T_Shape
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],   # O_SHAPE
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]   # Z_SHAPE
]

var active_piece = []
var placed_pieces = []
var current_ghost_position = Vector2i(0, 0)

# Layer IDs
const BOARD_LAYER = 0
const GHOST_LAYER = 1


var move_cooldown = 0.1  
var move_timers = {}

@onready var sound_manager = get_node("../../GameSoundManager")
@onready var input_manager = get_node("../../InputManager")


const MOVE_DIRECTIONS = {
	"ui_left": Vector2i(-1, 0),
	"ui_right": Vector2i(1, 0),
	"ui_down": Vector2i(0, 1),
	"ui_up": Vector2i(0, -1)
}

signal combination_complete(result_piece)
var is_ai_turn = false

func _ready():
	# initialize_move_timers()
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)  # Add ghost layer if it doesn't exist
	print("Combination map ready")
	active_piece = get_random_piece()
	set_process_unhandled_input(true)
	update_ghost_piece()
	reset()
	input_manager.connect("move_piece", Callable(self, "_on_move_piece"))
	input_manager.connect("rotate_piece", Callable(self, "_on_rotate_piece"))
	input_manager.connect("place_piece", Callable(self, "_on_place_piece"))
	
func _input(event):
	if is_ai_turn:
		return

	if event is InputEventMouseMotion:
		var local_position = get_local_mouse_position()
		var map_position = local_to_map(local_position)
		if is_within_bounds(map_position):
			current_ghost_position = map_position
			update_ghost_piece()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position = get_local_mouse_position()
		var map_position = local_to_map(click_position)
		if is_within_bounds(map_position):
			_on_tile_clicked(map_position)

func is_within_bounds(position: Vector2i) -> bool:
	return (position.x >= BOARD_OFFSET.x and position.x < BOARD_OFFSET.x + BOARD_WIDTH and
			position.y >= BOARD_OFFSET.y and position.y < BOARD_OFFSET.y + BOARD_HEIGHT)

func _on_move_piece(direction: Vector2i):
	if not is_ai_turn:
		move_piece(direction)

func _on_rotate_piece(clockwise: bool):
	if not is_ai_turn:
		rotate_piece(current_ghost_position, clockwise)

func _on_place_piece():
	if not is_ai_turn:
		_on_tile_clicked(current_ghost_position)

func move_piece(direction: Vector2i):
	var new_position = current_ghost_position + direction
	new_position.x = clamp(new_position.x, BOARD_OFFSET.x, BOARD_OFFSET.x + BOARD_WIDTH - 1)
	new_position.y = clamp(new_position.y, BOARD_OFFSET.y, BOARD_OFFSET.y + BOARD_HEIGHT - 1)
	if new_position != current_ghost_position:
		current_ghost_position = new_position
		update_ghost_piece()
		sound_manager.play_move_sound()

func reset():
	for piece in placed_pieces:
		for tile in piece:
			set_cell(BOARD_LAYER, tile, TILESET_SOURCE_ID, EMPTY_TILE)
	clear_layer(GHOST_LAYER)
	placed_pieces = []
	active_piece = get_random_piece()
	current_ghost_position = Vector2i(0, 0)
	if not is_ai_turn:
		update_ghost_piece()
	print("Combination map reset")

func _on_combination_complete(combined_piece: Array[Vector2i]):
	emit_signal("combination_complete", combined_piece)
	reset()

func get_random_piece():
	return ALL_SHAPES[randi() % ALL_SHAPES.size()]

func can_place_piece(base_position: Vector2i) -> bool:
	if placed_pieces.size() >= 2:
		return false 

	if placed_pieces.is_empty():
		return true
		
	for offset in active_piece:
		var tile_position = base_position + offset
		if not is_within_bounds(tile_position):
			return false


	var overlaps = false
	for offset in active_piece:
		var tile_position = base_position + offset
		for placed_tile in placed_pieces[0]:
			if tile_position == placed_tile:
				overlaps = true
				break
		if overlaps:
			break

	return overlaps

func _on_tile_clicked(map_position: Vector2i):
	var game_manager = get_parent().get_parent()
	var player_tile = PLAYER_1_TILE if game_manager.current_player == Constants.Player.PLAYER_1 else PLAYER_2_TILE
	place_piece(map_position, player_tile)

func place_piece(base_position: Vector2i, tile: Vector2i):
	var game_manager = get_parent().get_parent()
	print_debug("Attempting to place piece at ", base_position)
	if can_place_piece(base_position):
		var new_piece = []
		var all_tiles_in_bounds = true
		for offset in active_piece:
			var tile_position = base_position + offset
			if not is_within_bounds(tile_position):
				all_tiles_in_bounds = false
				break
		
		if all_tiles_in_bounds:
			for offset in active_piece:
				var tile_position = base_position + offset
				set_cell(BOARD_LAYER, tile_position, TILESET_SOURCE_ID, tile)
				new_piece.append(tile_position)

			placed_pieces.append(new_piece)
			print_debug("Piece placed. Total pieces placed: ", placed_pieces.size())

			if placed_pieces.size() == 2:
				var result_piece = combine_pieces()
				print_debug("Combination complete. Result: ", result_piece)
				if game_manager.game_mode == game_manager.GameMode.SINGLE_PLAYER and game_manager.current_player == Constants.Player.PLAYER_2:
					await get_tree().create_timer(0.5).timeout  
				var sound = "shadow" if game_manager.current_player == Constants.Player.PLAYER_1 else "light"
				sound_manager.play_combine_sound(sound)  # Add this line
				_on_combination_complete(result_piece)
			else:
				active_piece = get_random_piece()
				var sound = "shadow" if game_manager.current_player == Constants.Player.PLAYER_1 else "light"
				sound_manager.play_place_sound(sound)  # Add this line				
				print_debug("New active piece: ", active_piece)
			update_ghost_piece()
		else:
			print_debug("Cannot place piece: not all tiles are within bounds")
	else:
		print_debug("Cannot place piece at ", base_position)

func set_ai_turn(value: bool):
	is_ai_turn = value
	if is_ai_turn:
		clear_layer(GHOST_LAYER)
func update_ghost_piece(map_position = null):
	if is_ai_turn:
		clear_layer(GHOST_LAYER)
		return

	clear_layer(GHOST_LAYER)
	var game_manager = get_parent().get_parent()

	if active_piece.is_empty():
		return

	var current_player_tile = PLAYER_1_TILE if game_manager.current_player == Constants.Player.PLAYER_1 else PLAYER_2_TILE
	var ghost_tile

	var can_place = can_place_piece(current_ghost_position)
	
	if game_manager.current_player == Constants.Player.PLAYER_1:
		ghost_tile = GHOST_TILE if can_place else INVALID_GHOST_TILE
	else:
		ghost_tile = GHOST_TILE_OPPONENT if can_place else INVALID_GHOST_TILE_PLAYER_2

	for offset in active_piece:
		var tile_position = current_ghost_position + offset
		if is_within_bounds(tile_position):
			set_cell(GHOST_LAYER, tile_position, TILESET_SOURCE_ID, ghost_tile)
			
func combine_pieces() -> Array[Vector2i]:
	var all_tiles: Array[Vector2i] = []
	for piece in placed_pieces:
		all_tiles.append_array(piece)

	# Remove duplicates (overlapping tiles)
	var unique_tiles: Array[Vector2i] = []
	for tile in all_tiles:
		if tile not in unique_tiles:
			unique_tiles.append(tile)

	var min_x = unique_tiles[0].x
	var min_y = unique_tiles[0].y
	var max_x = unique_tiles[0].x
	var max_y = unique_tiles[0].y
	for tile in unique_tiles:
		min_x = min(min_x, tile.x)
		min_y = min(min_y, tile.y)
		max_x = max(max_x, tile.x)
		max_y = max(max_y, tile.y)

	var normalized_shape: Array[Vector2i] = []
	for tile in unique_tiles:
		normalized_shape.append(Vector2i(tile.x - min_x, tile.y - min_y))

	print("Combined and normalized shape: ", normalized_shape)
	return normalized_shape
	
func rotate_piece(mouse_position: Vector2i, clockwise: bool = true):
	if placed_pieces.size() >= 2:
		return  # Don't rotate after combination

	var rotated_piece = []
	for tile in active_piece:
		var rotated_pos = Vector2i(-tile.y, tile.x) if clockwise else Vector2i(tile.y, -tile.x)
		rotated_piece.append(rotated_pos)

	active_piece = rotated_piece
	update_ghost_piece()
	sound_manager.play_move_sound()
