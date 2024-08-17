class_name AIOpponent

extends Node

var game_manager: game_manager
var combination_board: Control
var tile_map: TileMap


func _init(manager: game_manager, combo_board: Control, main_board: TileMap) -> void:
	game_manager = manager
	combination_board = combo_board
	tile_map = main_board


func make_combination() -> void:
	var combination_map: TileMap = combination_board.get_node("CombinationMap")
	var current_player_tile: Vector2i = (
		combination_map.PLAYER_1_TILE
		if game_manager.current_player == game_manager.Player.PLAYER_1
		else combination_map.PLAYER_2_TILE
	)

	# Find first valid placement for this piece
	for position in combination_map.get_used_cells(combination_map.BOARD_LAYER):
		if combination_map.can_place_piece(position):
			combination_map.place_piece(position, current_player_tile)
			break
	
	await game_manager.get_tree().create_timer(0.5).timeout
	
	# Find the placement of the second piece that will maximise the size of the combined piece
	var best_second_placement = find_best_second_placement(combination_map)
	combination_map.place_piece(best_second_placement.position, current_player_tile)



func find_best_second_placement(combination_map: TileMap) -> Dictionary:
	var best_placement := {}
	var max_combined_size: int = 0

	for position in combination_map.get_used_cells(combination_map.BOARD_LAYER):
		if combination_map.can_place_piece(position):
			# Simulate placing the piece
			var simulated_pieces = combination_map.placed_pieces.duplicate(true)
			simulated_pieces.append(get_piece_tiles(combination_map.active_piece, position))

			# Calculate the size of the combined piece
			var combined_size: int = calculate_combined_size(simulated_pieces)

			if combined_size > max_combined_size:
				max_combined_size = combined_size
				best_placement = {"position": position, "size": combined_size}
	
	return best_placement


func get_piece_tiles(piece: Array, base_position: Vector2i) -> Array:
	var tiles = []
	for offset in piece:
		tiles.append(base_position + offset)
	return tiles


func calculate_combined_size(pieces: Array) -> int:
	var all_tiles = []
	for piece in pieces:
		all_tiles.append(piece)
	
	var unique_tiles = []
	for tile in all_tiles:
		if tile not in unique_tiles:
			unique_tiles.append(tile)
	
	return unique_tiles.size()


func place_piece() -> void:
	var current_player_tile: Vector2i = (
		tile_map.PLAYER_1_TILE
		if game_manager.current_player == game_manager.Player.PLAYER_1
		else tile_map.PLAYER_2_TILE
	)

	var possible_placements: Array[Dictionary] = get_possible_placements(current_player_tile)

	if possible_placements.is_empty():
		print("AI couldn't find a valid position to place the piece.")
		return

	var best_placement: Dictionary = choose_best_placement(possible_placements)

	tile_map.place_piece(best_placement.piece, best_placement.position, current_player_tile)


func get_possible_placements(current_player_tile: Vector2i) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	var board_rect: Rect2i = tile_map.get_used_rect()

	for rotation in range(4):  # Try all 4 rotations
		var rotated_piece: Array[Vector2i] = tile_map.rotate_piece(tile_map.active_piece, rotation)

		for y in range(board_rect.position.y, board_rect.end.y):
			for x in range(board_rect.position.x, board_rect.end.x):
				var position: Vector2i = Vector2i(x, y)
				if tile_map.can_place_piece(rotated_piece, position, current_player_tile):
					placements.append(
						{
							"position": position,
							"piece": rotated_piece,
							"score":
							evaluate_placement(rotated_piece, position, current_player_tile)
						}
					)

	return placements


func choose_best_placement(placements: Array[Dictionary]) -> Dictionary:
	var best_placement := {}
	var best_score = -INF

	for placement in placements:
		if placement.score > best_score:
			best_score = placement.score
			best_placement = placement

	return best_placement


func evaluate_placement(
	piece: Array[Vector2i], position: Vector2i, current_player_tile: Vector2i
) -> float:
	var score := 0.0

	for offset in piece:
		var position_to_check: Vector2i = position + offset
		var existing_tile: Vector2i = tile_map.get_cell_atlas_coords(
			tile_map.BOARD_LAYER, position_to_check
		)
		if existing_tile == tile_map.EMPTY_TILE:
			score += 1.0

	var opponent_tile = (
		tile_map.PLAYER_2_TILE
		if current_player_tile == tile_map.PLAYER_1_TILE
		else tile_map.PLAYER_1_TILE
	)
	for offset in piece:
		var position_to_check: Vector2i = position + offset
		var existing_tile: Vector2i = tile_map.get_cell_atlas_coords(
			tile_map.BOARD_LAYER, position_to_check
		)
		if existing_tile == opponent_tile:
			score += 2.0

	score += randf_range(0, 0.5)

	return score
