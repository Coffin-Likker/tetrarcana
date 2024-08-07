extends Node

var game_manager
var combination_board
var tile_map

func _init(manager, combo_board, main_board):
	game_manager = manager
	combination_board = combo_board
	tile_map = main_board

func make_combination():
	var combination_map = combination_board.get_node("CombinationMap")
	var current_player_tile = combination_map.PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else combination_map.PLAYER_2_TILE
	
	var first_position = Vector2i(0, 0)
	combination_map.place_piece(first_position, current_player_tile)
	await game_manager.get_tree().create_timer(0.5).timeout
	var second_position = Vector2i(1, 0)
	combination_map.place_piece(second_position, current_player_tile)

func place_piece():
	var current_player_tile = tile_map.PLAYER_1_TILE if game_manager.current_player == game_manager.Player.PLAYER_1 else tile_map.PLAYER_2_TILE
	var board_rect = tile_map.get_used_rect()
	for y in range(board_rect.position.y, board_rect.end.y):
		for x in range(board_rect.position.x, board_rect.end.x):
			var position = Vector2i(x, y)
			if tile_map.can_place_piece(position, current_player_tile):
				tile_map.place_piece(position, current_player_tile)
				return

	print("AI couldn't find a valid position to place the piece")
