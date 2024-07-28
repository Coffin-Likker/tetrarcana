extends Node2D

class_name game_manager

enum GameState { MENU, PLAYING, GAME_OVER }
enum Player { PLAYER_1, PLAYER_2 }
enum WinResult { PLAYER_1_WIN, PLAYER_2_WIN, TIE }

var game_state: GameState 
var current_player: Player 
var turn_count: int = 0
const MAX_TURNS: int = 16
var winner: WinResult
var winner_message: String

@onready var tile_map: TileMap = $TileMap
@onready var game_manager = $"."
@onready var ui = $"../ui"
@onready var menu_manager = $"../MenuManager"

func _ready():
	tile_map.connect("piece_placed", Callable(self, "_on_piece_placed"))
	#ui.connect("game_started", Callable(self, "game_started"))
	menu_manager.connect("go_main_menu", Callable(self, "go_main_menu"))
	#ui.connect("restart_game", Callable(self, "game_started"))
	menu_manager.connect("game_started", Callable(self, "game_started"))
	#menu_manager.connect("go_main_menu", Callable(self, "go_main_menu"))
	#menu_manager.connect("restart_game", Callable(self, "game_started"))
	game_state = GameState.MENU

func game_started():
	game_state = GameState.PLAYING
	print_debug("game_started", game_state)
	current_player = Player.PLAYER_1
	print_debug("game_started", current_player)
	turn_count = 0
	tile_map.reset()

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
	menu_manager.on_game_over(winner_message)

func go_main_menu():
	game_state = GameState.MENU

func _on_piece_placed():
	print_debug("printing the game state", game_state)
	if game_state != GameState.PLAYING:
		return
	end_turn()

func end_turn():
	turn_count += 1
	print_debug("Turn " + str(turn_count) + " completed")
	if turn_count >= MAX_TURNS:
		end_game()
	else:
		switch_player()
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
