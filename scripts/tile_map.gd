extends TileMap

# Define the S-shape Tetris piece
const S_SHAPE = [
	Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1)
]

const I_SHAPE = [
	Vector2i(-1,0), Vector2i(0,0),
	Vector2i(1,0), Vector2i(2,0) 
]

const L_Shape = [
	Vector2i(-1,0), Vector2i(0,0),
	Vector2i(1,0), Vector2i(1,1) 
]

const J_Shape = [
	Vector2i(-1,0), Vector2i(0,0),
	Vector2i(1,0), Vector2i(1,1) 
]

const T_Shape = [
	Vector2i(-1,0), Vector2i(0,0), 
	Vector2i(1,0), Vector2i(0,1)
]

const O_SHAPE = [
	Vector2i(0,0), Vector2i(1,0), 
	Vector2i(0,1), Vector2i(1,1)
]

const Z_SHAPE = [
	Vector2i(-1,0), Vector2i(0,0), 
	Vector2i(0,1), Vector2i(1,1)
]

const ALL_SHAPES = [S_SHAPE, I_SHAPE, L_Shape, J_Shape, T_Shape, O_SHAPE, Z_SHAPE]
# Tile IDs
const EMPTY_TILE = Vector2i(0, 0)
const GHOST_TILE = Vector2i(16, 0)
const GHOST_TILE_OPPONENT = Vector2i(15, 0)
const INVALID_GHOST_TILE = Vector2i(14, 0) 

# Layer IDs
const BOARD_LAYER = 0
const GHOST_LAYER = 1


enum Player { PLAYER_1, PLAYER_2 }
enum GameState { MENU, PLAYING, GAME_OVER }

# Tile IDs for each player
const PLAYER_1_TILE = Vector2i(16, 5)
const PLAYER_2_TILE = Vector2i(16, 6)  # Red tile

var current_ghost_position = Vector2i(0, 0)
var active_piece = []
var grab_bag = []

signal piece_placed
var game_manager_node = get_parent()
var board_rect: Rect2i

func _ready():
	set_process_unhandled_input(true)
	print_debug("TileMap initialized. Ready to process input.")
	refill_grab_bag()
	active_piece = get_next_piece()
	
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)
	
	board_rect = get_used_rect()

func reset():
	print_debug("Resetting the game board")

	# Clear both layers of the TileMap
	var board_size = get_used_rect().size
	for x in range(board_size.x):
		for y in range(board_size.y):
			var cell_pos = Vector2i(x, y)
			var cell_atlas_coords = get_cell_atlas_coords(BOARD_LAYER, cell_pos)
			if cell_atlas_coords != EMPTY_TILE:
				set_cell(BOARD_LAYER, cell_pos, 0, EMPTY_TILE)

	clear_layer(GHOST_LAYER)

	# Reset game-specific variables
	current_ghost_position = Vector2i(0, 0)
	active_piece = []
	grab_bag = []

	# Refill the grab bag and get a new active piece
	refill_grab_bag()
	active_piece = get_next_piece()

	# Ensure there are at least two layers (BOARD_LAYER and GHOST_LAYER)
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)

	# Update the ghost piece to reflect the new active piece
	update_ghost_piece()

	print_debug("Game board reset complete")


func _input(event):
	if get_parent().game_state != GameState.PLAYING:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position = get_local_mouse_position()
		var map_position = local_to_map(click_position)
		
		for offset in active_piece:
			var tile_position = map_position + offset
			if (tile_position.x < board_rect.position.x or
				tile_position.x >= board_rect.end.x or
				tile_position.y < board_rect.position.y or
				tile_position.y >= board_rect.end.y):
					return
		
		_on_tile_clicked(map_position)

func _process(_delta):
	if Input.is_action_just_pressed("rotate_clockwise"):
		rotate_piece(1)
	elif Input.is_action_just_pressed("rotate_counterclockwise"):
		rotate_piece(-1)

func _unhandled_input(event):
	if event is InputEventMouseMotion and  get_parent().game_state == GameState.PLAYING:
		update_ghost_piece()

func _on_tile_clicked(map_position: Vector2i):	
		var player_tile = PLAYER_1_TILE if get_parent().current_player == Player.PLAYER_1 else PLAYER_2_TILE
		place_piece(map_position, player_tile)

func place_piece(map_position: Vector2i, tile: Vector2i):
	print_debug("Placing piece at base position: ", map_position)
	
	if game_manager_node.turn_count < 2 or can_place_piece(map_position, tile):
		for offset in active_piece:
			var tile_position = map_position + offset
			set_cell(BOARD_LAYER, tile_position, 0, tile)
		active_piece = get_next_piece()
		update_ghost_piece()
		emit_signal("piece_placed")
	else:
		print_debug("Invalid placement")

func can_place_piece(map_position: Vector2i, tile: Vector2i) -> bool:
	var overlaps_own_color = false
	for offset in active_piece:
		var tile_position = map_position + offset
		var existing_tile = get_cell_atlas_coords(BOARD_LAYER, tile_position)
		if existing_tile == tile:
			overlaps_own_color = true
			break
		elif existing_tile != EMPTY_TILE:
			return false  
	return overlaps_own_color

func clear_connected_piece(start_position: Vector2i):
	print_debug("Starting to clear connected piece from position: ", start_position)
	var start_tile = get_cell_atlas_coords(BOARD_LAYER, start_position)
	print_debug("Start tile atlas coords: ", start_tile)
	if start_tile == EMPTY_TILE:
		print_debug("Start tile is empty, returning")
		return
	
	var to_clear = [start_position]
	var checked = {}
	
	while not to_clear.is_empty():
		var current_position = to_clear.pop_back()
		print_debug("Checking tile at position: ", current_position)
		if current_position in checked:
			print_debug("Tile already checked, skipping")
			continue
		
		checked[current_position] = true
		var current_tile = get_cell_atlas_coords(BOARD_LAYER, current_position)
		print_debug("Current tile atlas coords: ", current_tile)
		if current_tile == start_tile:
			print_debug("Clearing tile at position: ", current_position)
			set_cell(BOARD_LAYER, current_position, 0, EMPTY_TILE)
			for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next_position = current_position + direction
				if next_position not in checked:
					to_clear.append(next_position)
					print_debug("Added adjacent tile to check: ", next_position)
		
		# print_debug("Finished clearing connected piece")
		# print_debug("Updating ghost pieces after clearing")
		update_ghost_piece()

func update_ghost_piece():
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)


	if map_position != current_ghost_position:
		current_ghost_position = map_position

	clear_layer(GHOST_LAYER)
	
	var current_player_tile = PLAYER_1_TILE if game_manager_node.current_player == game_manager_node.Player.PLAYER_1 else PLAYER_2_TILE
	var ghost_tile = GHOST_TILE if game_manager_node.current_player == game_manager_node.Player.PLAYER_1 else GHOST_TILE_OPPONENT

	var can_place = game_manager_node.turn_count < 2 or can_place_piece(current_ghost_position, current_player_tile)
	ghost_tile = ghost_tile if can_place else INVALID_GHOST_TILE

	for offset in active_piece:
		var tile_position = current_ghost_position + offset
		if get_cell_atlas_coords(BOARD_LAYER, tile_position) == EMPTY_TILE:
			set_cell(GHOST_LAYER, tile_position, 0, ghost_tile)

func rotate_piece(direction: int):
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
		update_ghost_piece()

func can_rotate():
	# Implement rotation validity check here
	return true
	
func refill_grab_bag():
	grab_bag = ALL_SHAPES.duplicate()
	grab_bag.shuffle()

func get_next_piece():
	if grab_bag.is_empty():
		refill_grab_bag()
	return grab_bag.pop_back()
