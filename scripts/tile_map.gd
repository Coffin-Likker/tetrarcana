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

# Tile IDs for each player
# THIS NEEDS FIXING 
# we neeed Player 1 and 2 color, that's also going to be used when it's respective piece CAN BE PLACED.
# and then we need the Obscure version of Player 1 and 2 color, that symbolize when it's noot possible to place a piece 
# and empty tile, so 5 in total 
# I think refactoring as to be done where the INVALID_GHOST_TILE becomes INVALID_GHOST_TILE_PLAYER_1 and INVALID_GHOST_TILE_PLAYER_2
# OR refact the Ghost tiles temselves and remove INVALID_GHOST_TILE from the code
const PLAYER_1_TILE = Vector2i(0, 0)
const PLAYER_2_TILE = Vector2i(2, 0)  # Red tile
const EMPTY_TILE = Vector2i(4, 0)
const GHOST_TILE = Vector2i(0, 0)
const GHOST_TILE_OPPONENT = Vector2i(2, 0)
const INVALID_GHOST_TILE = Vector2i(1, 0) 
const INVALID_GHOST_TILE_OPPONENT = Vector2i(3,0)

# Starting position constants
const PLAYER_1_START_OFFSET = Vector2i(1, -2)  # Bottom left, 2 rows from bottom
const PLAYER_2_START_OFFSET = Vector2i(-2, -2) # Bottom right, 2 rows from bottom

# Layer constants
const BOARD_LAYER = 0
const GHOST_LAYER = 1
const GHOST_LAYER_Z_INDEX = 1

enum Player { PLAYER_1, PLAYER_2 }
enum GameState { MENU, PLAYING, GAME_OVER }

var current_ghost_position = Vector2i(0, 0)
var active_piece = []
var grab_bag = []

signal piece_placed

var board_rect: Rect2i
var move_cooldown = 0.1  # Time in seconds between moves when key is held
var move_timers = {}
@onready var move_sounds: Array[AudioStreamPlayer] = [
	$MovePieceSound,
	$MovePieceSound2,
	$MovePieceSound3,
	$MovePieceSound4,
	$MovePieceSound5,
	$MovePieceSound6,
	$MovePieceSound7,
	$MovePieceSound8,
	$MovePieceSound9,
	$MovePieceSound10
]

@onready var light_place_sound = $LightPlaceSound
@onready var shadow_place_sound = $ShadowPlaceSound


var current_sound_index: int = 0

const MOVE_DIRECTIONS = {
	"ui_left": Vector2i(-1, 0),
	"ui_right": Vector2i(1, 0),
	"ui_down": Vector2i(0, 1),
	"ui_up": Vector2i(0, -1)
}

func play_placing_sound():
	var sound = light_place_sound if get_parent().current_player == Player.PLAYER_1 else shadow_place_sound
	sound.play()
	
func initialize_move_timers():
	for action in MOVE_DIRECTIONS.keys():
		move_timers[action] = 0.0

func _ready():
	InputMap.load_from_project_settings()
	set_process_unhandled_input(true)
	print_debug("TileMap initialized. Ready to process input.")
	active_piece = get_next_piece()
	
	initialize_move_timers()
	
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)
	
	set_layer_z_index(GHOST_LAYER, GHOST_LAYER_Z_INDEX)
	
	board_rect = get_used_rect()
	current_ghost_position = Vector2i(
		board_rect.position.x + 1,  # One column from the left edge
		board_rect.end.y - 3        # Three rows from the bottom
	)
	
	
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

func play_move_sound():
	move_sounds[current_sound_index].play()
	current_sound_index = (current_sound_index + 1) % move_sounds.size()

func _input(event):
	var game_manager = get_parent()
	if game_manager.game_state != GameState.PLAYING:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position = get_local_mouse_position()
		var map_position = local_to_map(click_position)
		
		if is_valid_position(map_position):
			_on_tile_clicked(map_position)

func handle_movement(delta):
	for action in MOVE_DIRECTIONS:
		if Input.is_action_pressed(action):
			move_timers[action] += delta
			if move_timers[action] >= move_cooldown:
				play_move_sound()
				move_piece(MOVE_DIRECTIONS[action])
				current_sound_index
				move_timers[action] = 0
		else:
			move_timers[action] = move_cooldown

func _process(delta):
	if get_parent().game_state != GameState.PLAYING:
		return
		
	if Input.is_action_just_pressed("rotate_clockwise"):
		play_move_sound()
		rotate_piece(1)
	elif Input.is_action_just_pressed("rotate_counterclockwise"):
		play_move_sound()		
		rotate_piece(-1)
		
	handle_movement(delta)

	if Input.is_action_just_pressed("place_piece"):
		_on_tile_clicked(current_ghost_position)
		
func move_piece(direction: Vector2i):
	var new_position = current_ghost_position + direction
	if is_valid_position(new_position):
		current_ghost_position = new_position
		update_ghost_piece()


func is_valid_position(position: Vector2i) -> bool:
	for offset in active_piece:
		var tile_position = position + offset
		if (tile_position.x < board_rect.position.x or
			tile_position.x >= board_rect.end.x or
			tile_position.y < board_rect.position.y or
			tile_position.y >= board_rect.end.y):
				return false	
	return true

func _unhandled_input(event):
	var game_manager = get_parent()
	
	if event is InputEventMouseMotion and game_manager.game_state == GameState.PLAYING:
		var map_position = local_to_map(get_local_mouse_position())
		if is_valid_position(map_position):
			current_ghost_position = map_position
			update_ghost_piece()

func _on_tile_clicked(map_position: Vector2i):	
	var game_manager = get_parent()
	var player_tile = PLAYER_1_TILE if game_manager.current_player == Player.PLAYER_1 else PLAYER_2_TILE
	place_piece(map_position, player_tile)

func place_piece(map_position: Vector2i, tile: Vector2i):
	var game_manager = get_parent()
	print_debug("Placing piece at base position: ", map_position)
	
	if game_manager.turn_count < 2 or can_place_piece(map_position, tile):
		for offset in active_piece:
			var tile_position = map_position + offset
			set_cell(BOARD_LAYER, tile_position, 0, tile)
		active_piece = get_next_piece()
		current_sound_index = 0
		play_placing_sound()
		set_position_for_new_piece()
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
	return overlaps_own_color

func update_ghost_piece():
	clear_layer(GHOST_LAYER)
	var game_manager = get_parent()
	var current_player_tile = PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else PLAYER_2_TILE
	var can_place = game_manager.turn_count < 2 or can_place_piece(current_ghost_position, current_player_tile)
	var ghost_tile
	if game_manager.current_player == game_manager.Player.PLAYER_1:
		ghost_tile = GHOST_TILE if can_place else INVALID_GHOST_TILE
	else:
		ghost_tile = GHOST_TILE_OPPONENT if can_place else INVALID_GHOST_TILE_OPPONENT

	for offset in active_piece:
		var tile_position = current_ghost_position + offset
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
	
func set_position_for_new_piece():
	var board_size = board_rect.size
	var game_manager = get_parent()
	
	if game_manager.current_player == Player.PLAYER_2:
		# Set position to bottom left for Player 2
		current_ghost_position = Vector2i(
			board_rect.position.x + 1,  # One column from the left edge
			board_rect.end.y - 3		# Three rows from the bottom
		)
	else:
		# Set position to bottom right for Player 1
		current_ghost_position = Vector2i(
			board_rect.end.x - 2,  # Two columns from the right edge
			board_rect.end.y - 3   # Three rows from the bottom
		)
	
	# Ensure the piece is within the valid board area
	while not is_valid_position(current_ghost_position):
		current_ghost_position.y -= 1
		
		# If we've moved the piece all the way to the top and it's still not valid,
		# try shifting it horizontally towards the center
		if current_ghost_position.y < board_rect.position.y:
			current_ghost_position.y = board_rect.end.y - 1
			if game_manager.current_player == Player.PLAYER_2:
				current_ghost_position.x += 1
			else:
				current_ghost_position.x -= 1
				
		# If we've exhausted all positions, place it in the center of the board
		if (current_ghost_position.x < board_rect.position.x or 
			current_ghost_position.x >= board_rect.end.x):
			current_ghost_position = Vector2i(
				board_rect.position.x + board_size.x / 2,
				board_rect.position.y + board_size.y / 2
			)
			break
	
	update_ghost_piece()

