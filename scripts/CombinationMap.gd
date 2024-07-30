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

signal combination_complete(result_piece)

func _ready():
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)  # Add ghost layer if it doesn't exist
	print("Combination map ready")
	active_piece = get_random_piece()
	update_ghost_piece()
	reset()

func reset():
	for piece in placed_pieces:
		for tile in piece:
			set_cell(BOARD_LAYER, tile, TILESET_SOURCE_ID, EMPTY_TILE)
	clear_layer(GHOST_LAYER)
	placed_pieces = []
	active_piece = get_random_piece()
	current_ghost_position = Vector2i(0, 0)
	update_ghost_piece()
	print("Combination map reset")

func _on_combination_complete(combined_piece):
	emit_signal("combination_complete", combined_piece)
	reset()

func get_random_piece():
	return ALL_SHAPES[randi() % ALL_SHAPES.size()]

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var map_position = local_to_map(get_local_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_tile_clicked(map_position)
			print("Attempt to place piece at ", map_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			rotate_piece(map_position)
			print("Attempt to rotate piece at ", map_position)
	elif event is InputEventMouseMotion:
		update_ghost_piece()

func is_within_bounds(position: Vector2i) -> bool:
	return (position.x >= BOARD_OFFSET.x and position.x < BOARD_OFFSET.x + BOARD_WIDTH and
	position.y >= BOARD_OFFSET.y and position.y < BOARD_OFFSET.y + BOARD_HEIGHT)

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
	var player_tile = PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else PLAYER_2_TILE
	place_piece(map_position, player_tile)

func place_piece(base_position: Vector2i, tile: Vector2i):
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
				_on_combination_complete(result_piece)
			else:
				active_piece = get_random_piece()
				print_debug("New active piece: ", active_piece)
			update_ghost_piece()
		else:
			print_debug("Cannot place piece: not all tiles are within bounds")
	else:
		print_debug("Cannot place piece at ", base_position)

func update_ghost_piece():
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	clear_layer(GHOST_LAYER)
	var game_manager = get_parent().get_parent()
	#if is_within_bounds(map_position):

	map_position.x = clamp(map_position.x, BOARD_OFFSET.x, BOARD_OFFSET.x + BOARD_WIDTH - 1)
	map_position.y = clamp(map_position.y, BOARD_OFFSET.y, BOARD_OFFSET.y + BOARD_HEIGHT - 1)


	if map_position != current_ghost_position:
		current_ghost_position = map_position

	var can_place = can_place_piece(current_ghost_position)
	var all_tiles_in_bounds = true
	
	var ghost_tile 
		
	for offset in active_piece:
		var tile_position = current_ghost_position + offset
		if not is_within_bounds(tile_position):
			all_tiles_in_bounds = false
			break

	if game_manager.current_player == game_manager.Player.PLAYER_1:
		ghost_tile = GHOST_TILE if  (can_place and all_tiles_in_bounds) else INVALID_GHOST_TILE
	else:
		ghost_tile = GHOST_TILE_OPPONENT if  (can_place and all_tiles_in_bounds) else INVALID_GHOST_TILE_PLAYER_2

	for offset in active_piece:
		var tile_position = current_ghost_position + offset
		if is_within_bounds(tile_position):
			set_cell(GHOST_LAYER, tile_position, TILESET_SOURCE_ID, ghost_tile)
	#else:
		## If the mouse is outside the board, clear the current_ghost_position
		#current_ghost_position = Vector2i(0, 0)

func combine_pieces() -> Array:
	var all_tiles = []
	for piece in placed_pieces:
		all_tiles.append_array(piece)

	# Remove duplicates (overlapping tiles)
	var unique_tiles = []
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

	var normalized_shape = []
	for tile in unique_tiles:
		normalized_shape.append(Vector2i(tile.x - min_x, tile.y - min_y))

	print("Combined and normalized shape: ", normalized_shape)
	return normalized_shape
	
func rotate_piece(mouse_position: Vector2i):
	if placed_pieces.size() >= 2:
		return  # Don't rotate after combination

	var rotated_piece = []
	var pivot = Vector2i.ZERO

	# Find the tile closest to the mouse position
	var min_distance = INF
	for i in range(active_piece.size()):
		var tile = active_piece[i]
		var distance = (mouse_position - (current_ghost_position + tile)).length_squared()
		if distance < min_distance:
			min_distance = distance
			pivot = tile

	# Rotate around the pivot
	for tile in active_piece:
		var relative_pos = tile - pivot
		var rotated_pos = Vector2i(-relative_pos.y, relative_pos.x)  # 90-degree clockwise rotation
		rotated_piece.append(rotated_pos + pivot)

	# Adjust the position to keep the mouse on a tile and within bounds
	var offset = mouse_position - (current_ghost_position + pivot)
	var new_ghost_position = current_ghost_position + offset
	new_ghost_position.x = clamp(new_ghost_position.x, BOARD_OFFSET.x, BOARD_OFFSET.x + BOARD_WIDTH - 1)
	new_ghost_position.y = clamp(new_ghost_position.y, BOARD_OFFSET.y, BOARD_OFFSET.y + BOARD_HEIGHT - 1)
	
	# Check if the rotated piece is entirely within bounds
	#var is_valid_rotation = true
	#for tile in rotated_piece:
		#if not is_within_bounds(new_ghost_position + tile):
			#is_valid_rotation = false
			#break
	
	#if is_valid_rotation:
	active_piece = rotated_piece
	current_ghost_position = new_ghost_position
	update_ghost_piece()

