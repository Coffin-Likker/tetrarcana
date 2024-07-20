extends TileMap

# Define the S-shape Tetris piece
const S_SHAPE = [
	Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1),
]

# Tile IDs
const EMPTY_TILE = Vector2i(0, 0)
const PLAYER_1_TILE = Vector2i(16, 5)
const GHOST_TILE = Vector2i(16, 0)

# Layer IDs
const BOARD_LAYER = 0
const GHOST_LAYER = 1

var current_ghost_position = Vector2i(0, 0)

func _ready():
	set_process_unhandled_input(true)
	print("TileMap initialized. Ready to process input.")
	
	if get_layers_count() < 2:
		add_layer(GHOST_LAYER)

func _input(event):
	if not event is InputEventMouseButton or not event.pressed:
		return
	
	print("Input event detected: ", event.button_index)
	_on_tile_clicked(event.position, event.button_index)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		update_ghost_piece()

func _on_tile_clicked(click_position: Vector2, button_index: int):
	var base_position = local_to_map(to_local(click_position))
	print("Clicked tile position: ", base_position)
	
	match button_index:
		MOUSE_BUTTON_LEFT:
			print("Left click detected, placing piece")
			place_piece(base_position, S_SHAPE, PLAYER_1_TILE)
		MOUSE_BUTTON_RIGHT:
			print("Right click detected, clearing connected piece")
			clear_connected_piece(base_position)

func place_piece(base_position: Vector2i, shape: Array, tile: Vector2i):
	print("Placing piece at base position: ", base_position)
	for offset in shape:
		var tile_position = base_position + offset
		print("Setting tile at position: ", tile_position)
		set_cell(BOARD_LAYER, tile_position, 0, tile)
	print("Piece placed. Updating ghost piece.")
	update_ghost_piece()

func clear_connected_piece(start_position: Vector2i):
	print("Starting to clear connected piece from position: ", start_position)
	var start_tile = get_cell_atlas_coords(BOARD_LAYER, start_position)
	print("Start tile atlas coords: ", start_tile)
	if start_tile == EMPTY_TILE:
		print("Start tile is empty, returning")
		return
	
	var to_clear = [start_position]
	var checked = {}
	
	while not to_clear.is_empty():
		var current_position = to_clear.pop_back()
		print("Checking tile at position: ", current_position)
		if current_position in checked:
			print("Tile already checked, skipping")
			continue
		
		checked[current_position] = true
		var current_tile = get_cell_atlas_coords(BOARD_LAYER, current_position)
		print("Current tile atlas coords: ", current_tile)
		if current_tile == start_tile:
			print("Clearing tile at position: ", current_position)
			set_cell(BOARD_LAYER, current_position, 0, EMPTY_TILE)
			for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next_position = current_position + direction
				if next_position not in checked:
					to_clear.append(next_position)
					print("Added adjacent tile to check: ", next_position)
		
		print("Finished clearing connected piece")
		print("Updating ghost pieces after clearing")
		update_ghost_piece()

func update_ghost_piece():
	print("Updating ghost piece")
	var mouse_position = get_global_mouse_position()
	var base_position = local_to_map(to_local(mouse_position))
	
	if base_position != current_ghost_position:
		print("Ghost position changed from ", current_ghost_position, " to ", base_position)
		current_ghost_position = base_position
	
	clear_layer(GHOST_LAYER)
	
	print("Placing ghost tiles:")
	for offset in S_SHAPE:
			var tile_position = current_ghost_position + offset
			if get_cell_atlas_coords(BOARD_LAYER, tile_position) == EMPTY_TILE:
				set_cell(GHOST_LAYER, tile_position, 0, GHOST_TILE)
				print("Placed ghost tile at ", tile_position)
			else:
				print("Cannot place ghost tile at ", tile_position, ". Tile not empty.")
