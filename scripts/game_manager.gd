extends Node2D

class_name game_manager

enum GameState { MENU, COMBINING, PLACING, GAME_OVER }
enum Player { PLAYER_1, PLAYER_2 }
enum WinResult { PLAYER_1_WIN, PLAYER_2_WIN, TIE }

var game_state: GameState 
var current_player: Player 
var turn_count: int = 0
@export var MAX_TURNS: int = 2
var winner: WinResult
var winner_message: String

@onready var tile_map: TileMap = $TileMap
@onready var combination_board_p1 : Control = $CombinationBoardP1
@onready var combination_board_p2 : Control= $CombinationBoardP2
@onready var game_manager = $"."
@onready var menu_manager_node = $"../MenuManager"

func _ready():
	tile_map.connect("piece_placed", Callable(self, "_on_piece_placed"))
	menu_manager_node.connect("go_main_menu", Callable(self, "go_main_menu"))
	menu_manager_node.connect("game_started", Callable(self, "game_started"))
	combination_board_p1.connect("combination_complete", Callable(self, "on_combination_complete"))
	combination_board_p2.connect("combination_complete", Callable(self, "on_combination_complete"))
	game_state = GameState.MENU
	hide_combination_boards()

func game_started():
	game_state = GameState.COMBINING
	print_debug("game_started", game_state)
	current_player = Player.PLAYER_1
	print_debug("game_started", current_player)
	turn_count = 0
	tile_map.reset()
	show_combination_board(current_player)
	
func hide_combination_boards():
	combination_board_p1.hide_board()
	combination_board_p2.hide_board()

func show_combination_board(player: Player):
	hide_combination_boards()
	if player == Player.PLAYER_1:
		combination_board_p1.show_board()
		combination_board_p1.get_node("CombinationMap").reset()
	else:
		combination_board_p2.show_board()
		combination_board_p2.get_node("CombinationMap").reset()
	game_state = GameState.COMBINING


func on_combination_complete(combined_piece):
	game_state = GameState.PLACING
	tile_map.set_active_piece(combined_piece)
	hide_combination_boards()

func _on_piece_placed():
	if game_state != GameState.PLACING:
		return
	end_turn()

func end_game():
	game_state = GameState.GAME_OVER
	winner = determine_winner()  # Actually determine the winner
	match winner:
		WinResult.PLAYER_1_WIN:
			winner_message = "Game Over! Player 1 wins!"
		WinResult.PLAYER_2_WIN:
			winner_message = "Game Over! Player 2 wins!"
		WinResult.TIE:
			winner_message = "Game Over! It's a tie!"
	print_debug(winner_message)
	#ui.on_game_over(winner_message)
	menu_manager_node.on_game_over(winner_message)

func go_main_menu():
	hide_combination_boards()
	game_state = GameState.MENU

func end_turn():
	turn_count += 1
	print_debug("Turn " + str(turn_count) + " completed")
	if turn_count >= MAX_TURNS:
		end_game()
	else:
		switch_player()
		game_state = GameState.COMBINING
		show_combination_board(current_player)
		tile_map.update_for_new_turn(current_player)
		print_debug("Turn " + str(turn_count + 1) + " - Player " + str(current_player + 1) + "'s turn")

func switch_player():
	current_player = Player.PLAYER_2 if current_player == Player.PLAYER_1 else Player.PLAYER_1

func determine_winner() -> WinResult:
	var player1_tiles = 0
	var player2_tiles = 0
	var board_size = tile_map.get_used_rect().size
	for x in range(board_size.x):
		for y in range(board_size.y):
			var cell = tile_map.get_cell_atlas_coords(0, Vector2i(x, y))
			if cell == tile_map.PLAYER_1_TILE:
				player1_tiles += 1
			elif cell == tile_map.PLAYER_2_TILE:
				player2_tiles += 1
	
	print_debug("player1_tiles - ", player1_tiles)
	print_debug("player2_tiles - ", player2_tiles)
	
	if player1_tiles > player2_tiles:
		return WinResult.PLAYER_1_WIN
	elif player2_tiles > player1_tiles:
		return WinResult.PLAYER_2_WIN
	else:
		return WinResult.TIE
