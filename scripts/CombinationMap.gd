extends TileMap

const TILESET_SOURCE_ID = 3  # Make sure this matches your tileset source ID

const EMPTY_TILE = Vector2i(0, 0)  # Changed to represent no tile
const PLAYER_TILE = Vector2i(12, 11)  
const GHOST_TILE = Vector2i(13, 0)
const INVALID_GHOST_TILE = Vector2i(14, 0) 

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
	reset_game()

func reset_game():
	for piece in placed_pieces:
		for tile in piece:
			set_cell(BOARD_LAYER, tile, TILESET_SOURCE_ID, EMPTY_TILE)
	clear_layer(GHOST_LAYER)
	placed_pieces = []
	active_piece = get_random_piece()
	update_ghost_piece()
	print("Combination map reset")

func get_random_piece():
	return ALL_SHAPES[randi() % ALL_SHAPES.size()]

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var map_position = local_to_map(get_local_mouse_position())
		place_piece(map_position)
		print("Attempt to place piece at ", map_position)
	elif event is InputEventMouseMotion:
		update_ghost_piece()



func can_place_piece(base_position: Vector2i) -> bool:
	if placed_pieces.size() >= 2:
		return false 

	if placed_pieces.is_empty():
		return true

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

func place_piece(base_position: Vector2i):
	print_debug("Attempting to place piece at ", base_position)
	if can_place_piece(base_position):
		var new_piece = []
		for offset in active_piece:
			var tile_position = base_position + offset
			set_cell(BOARD_LAYER, tile_position, TILESET_SOURCE_ID, PLAYER_TILE)
			new_piece.append(tile_position)
		placed_pieces.append(new_piece)
		print_debug("Piece placed. Total pieces placed: ", placed_pieces.size())
		if placed_pieces.size() == 2:
			var result_piece = combine_pieces()
			print_debug("Combination complete. Result: ", result_piece)
			emit_signal("combination_complete", result_piece)
		else:
			active_piece = get_random_piece()
			print_debug("New active piece: ", active_piece)
		update_ghost_piece()
	else:
		print_debug("Cannot place piece at ", base_position)

func update_ghost_piece():
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)

	if map_position != current_ghost_position:
		current_ghost_position = map_position

	clear_layer(GHOST_LAYER)

	var can_place = can_place_piece(current_ghost_position)
	var ghost_tile = GHOST_TILE if can_place else INVALID_GHOST_TILE

	for offset in active_piece:
		var tile_position = current_ghost_position + offset
		set_cell(GHOST_LAYER, tile_position, TILESET_SOURCE_ID, ghost_tile)


func combine_pieces() -> Array:
	var all_tiles = []
	for piece in placed_pieces:
		all_tiles.append_array(piece)

	# Remove duplicates (overlapping tiles)
	var unique_tiles = []
	for tile in all_tiles:
		if tile not in unique_tiles:
			unique_tiles.append(tile)

	# Find the bounding box of the combined shape
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
