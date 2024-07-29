extends TileMap

const TILESET_SOURCE_ID = 1  # Make sure this matches your tileset source ID

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

@onready var player_2_place_sound = $LightPlaceSound
@onready var player_1_place_sound = $ShadowPlaceSound


var current_sound_index: int = 0

const MOVE_DIRECTIONS = {
	"ui_left": Vector2i(-1, 0),
	"ui_right": Vector2i(1, 0),
	"ui_down": Vector2i(0, 1),
	"ui_up": Vector2i(0, -1)
}

func play_placing_sound():
	var sound = player_2_place_sound if get_parent().current_player == Player.PLAYER_1 else player_1_place_sound
	sound.play()
	
func initialize_move_timers():
	for action in MOVE_DIRECTIONS.keys():
		move_timers[action] = 0.0

func set_active_piece(piece):
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	active_piece = piece
	update_ghost_piece(map_position)
	print_debug("Active piece set: ", active_piece)

func _ready():
	InputMap.load_from_project_settings()
	set_process_unhandled_input(true)
	print_debug("TileMap initialized. Ready to process input.")
	
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
	move_sounds[current_sound_index].play()
	current_sound_index = (current_sound_index + 1) % move_sounds.size()

func _input(event):
	if get_parent().game_state != get_parent().GameState.PLACING:
		return

	# if event is InputEventMouseMotion:
	# 	var map_position = local_to_map(get_local_mouse_position())
	# 	handle_mouse_movement(map_position)

	if event is InputEventMouseMotion:
		var local_position = get_local_mouse_position()
		var map_position = local_to_map(local_position)
		if get_used_rect().has_point(map_position):
			update_ghost_piece(map_position)
		else:
			clear_layer(GHOST_LAYER)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position = get_local_mouse_position()
		var map_position = local_to_map(click_position)
		if get_used_rect().has_point(map_position):
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

#FIX ROTATION BY COPYING IT IDENTICALLY FROM COMBINATION BOARD
func _process(delta):
	if get_parent().game_state != get_parent().GameState.PLACING:
		return
	if Input.is_action_just_pressed("rotate_clockwise"):
		play_move_sound()
		rotate_piece(1)
	elif Input.is_action_just_pressed("rotate_counterclockwise"):
		play_move_sound()
		rotate_piece(-1)
	
	handle_movement(delta)

	# if Input.is_action_just_pressed("place_piece"):
	# 	_on_tile_clicked(current_ghost_position)


func _unhandled_input(event):
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	var game_manager = get_parent()
	if event is InputEventMouseMotion and  game_manager.game_state == GameState.PLACING:
		if is_valid_position(map_position):
			update_ghost_piece(map_position)

func move_piece(direction: Vector2i):
	# var local_position = get_local_mouse_position()
	# var map_position = local_to_map(local_position)
	var new_position = current_ghost_position + direction
	if is_valid_position(new_position):
		current_ghost_position = new_position
		update_ghost_piece(new_position)

func is_valid_position(position: Vector2i) -> bool:
	for offset in active_piece:
		var tile_position = position + offset
		if (tile_position.x < board_rect.position.x or
			tile_position.x >= board_rect.end.x or
			tile_position.y < board_rect.position.y or
			tile_position.y >= board_rect.end.y):
				return false	
	return true

#func _input(event):
	#var game_manager = get_parent()
	#if game_manager.game_state != GameState.PLAYING:
		#return
		#
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#var click_position = get_local_mouse_position()
		#var map_position = local_to_map(click_position)
		#
		#for offset in active_piece:
			#var tile_position = map_position + offset
			#if (tile_position.x < board_rect.position.x or
				#tile_position.x >= board_rect.end.x or
				#tile_position.y < board_rect.position.y or
				#tile_position.y >= board_rect.end.y):
					#return
		#
		#_on_tile_clicked(map_position)


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
			set_cell(BOARD_LAYER, tile_position, TILESET_SOURCE_ID, tile)
		update_ghost_piece(map_position)
		current_sound_index = 0
		play_placing_sound()
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

func update_ghost_piece(map_position: Vector2i):
	clear_layer(GHOST_LAYER)

	if active_piece.is_empty():
		return

	if map_position != current_ghost_position:
		current_ghost_position = map_position

	var game_manager = get_parent()
	var current_player_tile = PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else PLAYER_2_TILE

	var can_place = get_parent().game_state == get_parent().GameState.PLACING and (game_manager.turn_count < 2 or can_place_piece(current_ghost_position, current_player_tile))
	var ghost_tile

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
		update_ghost_piece(map_position)

func set_position_for_new_piece():
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	var board_size = board_rect.size
	var game_manager = get_parent()
	
	if game_manager.current_player == Player.PLAYER_1:
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
			if game_manager.current_player == Player.PLAYER_1:
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
	
	update_ghost_piece(map_position)

func can_rotate():
	return true
	
func update_for_new_turn(new_player: Player):
	var local_position = get_local_mouse_position()
	var map_position = local_to_map(local_position)
	set_position_for_new_piece()
	update_ghost_piece(map_position)
	

func handle_mouse_movement(map_position: Vector2i):
	var new_position = map_position
	var valid_position = new_position
	
	# Check each block of the active piece
	for offset in active_piece:
		var block_position = new_position + offset
		if not is_within_board(block_position):
			# If any block is outside, adjust the position
			if block_position.x < board_rect.position.x:
				valid_position.x = max(valid_position.x, board_rect.position.x - offset.x)
			elif block_position.x >= board_rect.end.x:
				valid_position.x = min(valid_position.x, board_rect.end.x - 1 - offset.x)
			if block_position.y < board_rect.position.y:
				valid_position.y = max(valid_position.y, board_rect.position.y - offset.y)
			elif block_position.y >= board_rect.end.y:
				valid_position.y = min(valid_position.y, board_rect.end.y - 1 - offset.y)
	
	if valid_position != current_ghost_position:
		current_ghost_position = valid_position
		update_ghost_piece(valid_position)

func is_within_board(position: Vector2i) -> bool:
	return (position.x >= board_rect.position.x and
			position.x < board_rect.end.x and
			position.y >= board_rect.position.y and
			position.y < board_rect.end.y)
