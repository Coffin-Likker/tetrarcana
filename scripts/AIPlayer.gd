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
	var combination_map: Node = combination_board.get_node("CombinationMap")
	var current_player_tile   = combination_map.PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else combination_map.PLAYER_2_TILE
	
	var first_position: Vector2i = Vector2i(0, 0)
	combination_map.place_piece(first_position, current_player_tile)
	await game_manager.get_tree().create_timer(0.5).timeout
	var second_position: Vector2i = Vector2i(1, 0)
	combination_map.place_piece(second_position, current_player_tile)

func place_piece() -> void:
	var current_player_tile: Vector2i = tile_map.PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else tile_map.PLAYER_2_TILE
	
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
		var rotated_piece: Array[Vector2i] = rotate_piece(tile_map.active_piece, rotation)
		
		for y in range(board_rect.position.y, board_rect.end.y):
			for x in range(board_rect.position.x, board_rect.end.x):
				var position: Vector2i = Vector2i(x, y)
				if tile_map.can_place_piece(rotated_piece, position, current_player_tile):
					placements.append(
						{
							"position": position,
							"piece": rotated_piece,
							"score": evaluate_placement(rotated_piece, position, current_player_tile)
						}
					)
					
	return placements


func rotate_piece(piece: Array[Vector2i], rotation: int) -> Array[Vector2i]:
	var rotation_angle: float = PI/2 * rotation
	var rotation_transform: Transform2D = Transform2D().rotated(rotation_angle)
	
	var rotated_piece: Array[Vector2i] = []
	for block in piece:
		var rotated_block: Vector2 = rotation_transform * Vector2(block)
		rotated_piece.append(Vector2i(rotated_block))
	
	return rotated_piece


func choose_best_placement(placements: Array[Dictionary]) -> Dictionary:
	var best_placement := {}
	var best_score = -INF

	for placement in placements:
		if placement.score > best_score:
			best_score = placement.score
			best_placement = placement

	return best_placement

func evaluate_placement(piece: Array[Vector2i], position: Vector2i, current_player_tile: Vector2i) -> float:
	var score := 0.0

	for offset in piece:
		var position_to_check: Vector2i = position + offset
		var existing_tile: Vector2i     = tile_map.get_cell_atlas_coords(tile_map.BOARD_LAYER, position_to_check)
		if existing_tile == tile_map.EMPTY_TILE:
			score += 1.0

	var opponent_tile = tile_map.PLAYER_2_TILE if current_player_tile == tile_map.PLAYER_1_TILE else tile_map.PLAYER_1_TILE
	for offset in piece:
		var position_to_check: Vector2i = position + offset
		var existing_tile: Vector2i     = tile_map.get_cell_atlas_coords(tile_map.BOARD_LAYER, position_to_check)
		if existing_tile == opponent_tile:
			score += 2.0

	score += randf_range(0, 0.5)

	return score
