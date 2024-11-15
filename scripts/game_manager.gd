extends Node2D

class_name game_manager

enum WinResult { PLAYER_1_WIN, PLAYER_2_WIN, TIE }

var game_state: Constants.GameState
var current_player: Constants.Player
var turn_count: int = 0
var winner: WinResult
var winner_message: String

@onready var tile_map: GameBoard = $TileMap
@onready var combination_board_p1: Control = $CombinationBoardP1
@onready var combination_board_p2: Control = $CombinationBoardP2
@onready var game_manager = $"."
@onready var menu_manager_node = $"../MenuManager"
@onready var splash_screen = $"../SplashScreen"
@onready var potion_1: TextureProgressBar = $Potions/Potion1
@onready var potion_2: TextureProgressBar = $Potions/Potion2
@onready var potion_3: TextureProgressBar = $Potions/Potion3
@onready var potion_4: TextureProgressBar = $Potions/Potion4
@onready var potion_5: TextureProgressBar = $Potions/Potion5
@onready var potion_6: TextureProgressBar = $Potions/Potion6
@onready var potion_7: TextureProgressBar = $Potions/Potion7
@onready var potion_8: TextureProgressBar = $Potions/Potion8
@onready var sound_manager = $GameSoundManager
@onready var boundary_polygon: CollisionPolygon2D = $TileMap/BoardBoundary/CollisionPolygon2D

var total_tiles: int
var filled_tiles: int
var unique_filled_tiles: Dictionary

enum GameMode { MULTIPLAYER, SINGLE_PLAYER }
var game_mode = GameMode.MULTIPLAYER
var ai_player: AIOpponent


func _ready():
	tile_map.connect("piece_placed", Callable(self, "_on_piece_placed"))
	splash_screen.connect("go_main_menu", Callable(self, "go_main_menu"))
	menu_manager_node.connect("go_main_menu", Callable(self, "go_main_menu"))
	menu_manager_node.connect("game_started", Callable(self, "game_started"))
	menu_manager_node.connect(
		"single_player_game_started", Callable(self, "single_player_game_started")
	)
	combination_board_p1.connect("combination_complete", Callable(self, "on_combination_complete"))
	combination_board_p2.connect("combination_complete", Callable(self, "on_combination_complete"))
	game_state = Constants.GameState.MENU
	hide_combination_boards()
	
	total_tiles = tile_map.count_empty_tiles()


func game_started():
	game_mode = GameMode.MULTIPLAYER
	game_state = Constants.GameState.COMBINING
	current_player = Constants.Player.PLAYER_1
	turn_count = 0
	tile_map.reset()
	filled_tiles = 0
	update_progress_bar()
	unique_filled_tiles.clear()
	sound_manager.start_game_music()
	print("Game started. Mode: ", "Multiplayer" if game_mode == GameMode.MULTIPLAYER else "Single Player")
	show_combination_board(current_player)


func single_player_game_started():
	game_mode = GameMode.SINGLE_PLAYER
	ai_player = load("res://scripts/AIPlayer.gd").new(self, combination_board_p2, tile_map)
	game_state = Constants.GameState.COMBINING
	current_player = Constants.Player.PLAYER_1
	turn_count = 0
	tile_map.reset()
	filled_tiles = 0
	update_progress_bar()
	unique_filled_tiles.clear()
	sound_manager.start_game_music()
	print("Game started. Mode: ", "SinglePlayer" if game_mode == GameMode.SINGLE_PLAYER else "Multi Player")
	show_combination_board(current_player)

func hide_combination_boards():
	combination_board_p1.hide_board()
	combination_board_p2.hide_board()
	combination_board_p1.get_node("CombinationMap").set_ai_turn(true)  # Change this line
	combination_board_p2.get_node("CombinationMap").set_ai_turn(true)  # Change this line

func show_combination_board(player: Constants.Player):
	print("Showing combination board for player: ", player, " Game mode: ", game_mode)
	hide_combination_boards()
	var is_ai_turn = game_mode == GameMode.SINGLE_PLAYER and player == Constants.Player.PLAYER_2
	if not is_ai_turn:
		combination_board_p1.show_board()
		combination_board_p1.get_node("CombinationMap").set_ai_turn(false)
		combination_board_p1.get_node("CombinationMap").reset()
	else:
		combination_board_p2.show_board()
		combination_board_p2.get_node("CombinationMap").set_ai_turn(is_ai_turn)
		combination_board_p2.get_node("CombinationMap").reset()
	game_state = Constants.GameState.COMBINING
	sound_manager.play_parchment_sound()


func on_combination_complete(combined_piece: Array[Vector2i]):
	game_state = Constants.GameState.PLACING
	tile_map.clear_layer(tile_map.GHOST_LAYER)
	tile_map.set_active_piece(combined_piece)
	hide_combination_boards()


func _on_piece_placed():
	if game_state != Constants.GameState.PLACING:
		return
	filled_tiles += tile_map.active_piece.size()
	update_progress_bar()
	update_unique_filled_tiles()
	if (unique_filled_tiles.size() / float(total_tiles)) >= 0.75:
		end_game()
	else:
		end_turn()

## Update the dictionary of unique cells that have been filled by players
func update_unique_filled_tiles():
	for cell in tile_map.get_used_cells(tile_map.BOARD_LAYER):
		var atlas_coords = tile_map.get_cell_atlas_coords(tile_map.BOARD_LAYER, cell)
		if atlas_coords != tile_map.FULLY_EMPTY_TILE:
			unique_filled_tiles[cell] = true

func update_progress_bar():
	var fill_percentage = unique_filled_tiles.size() / float(total_tiles)
	potion_1.value = fill_percentage
	potion_2.value = fill_percentage
	potion_3.value = fill_percentage
	potion_4.value = fill_percentage
	potion_5.value = fill_percentage
	potion_6.value = fill_percentage
	potion_7.value = fill_percentage
	potion_8.value = fill_percentage


func end_game():
	potion_1.value = 1.1
	potion_2.value = 1.1
	potion_3.value = 1.1
	potion_4.value = 1.1
	potion_5.value = 1.1
	potion_6.value = 1.1
	potion_7.value = 1.1
	potion_8.value = 1.1
	game_state = Constants.GameState.GAME_OVER
	winner = determine_winner()
	match winner:
		WinResult.PLAYER_1_WIN:
			winner_message = "Game Over! Player 1 wins!"
			sound_manager.play_win_sound("shadow")  # Assuming Player 1 is shadow
		WinResult.PLAYER_2_WIN:
			winner_message = "Game Over! Player 2 wins!"
			sound_manager.play_win_sound("light")  # Assuming Player 2 is light
		WinResult.TIE:
			winner_message = "Game Over! It's a tie!"
			sound_manager.play_win_sound("shadow")  # Play any win sound for a tie
	#print_debug(winner_message)
	menu_manager_node.on_game_over(winner_message)


func go_main_menu():
	hide_combination_boards()
	game_state = Constants.GameState.MENU
	
func enable_player_input():
	# Enable input for player turn
	tile_map.set_process_unhandled_input(true)
	combination_board_p1.get_node("CombinationMap").set_process_unhandled_input(true)
	combination_board_p2.get_node("CombinationMap").set_process_unhandled_input(true)


func end_turn():
	print("End turn. Current player: ", current_player, " Game mode: ", game_mode)
	turn_count += 1
	switch_player()
	game_state = Constants.GameState.COMBINING
	show_combination_board(current_player)
	tile_map.update_for_new_turn(current_player)
	if game_mode == GameMode.SINGLE_PLAYER and current_player == Constants.Player.PLAYER_2:
		ai_turn()
	else:
		enable_player_input()


func ai_turn():
	print("AI turn started")
	# Disable player input during AI turn
	tile_map.set_process_unhandled_input(false)
	combination_board_p1.get_node("CombinationMap").set_process_unhandled_input(false)
	combination_board_p2.get_node("CombinationMap").set_process_unhandled_input(false)

	show_combination_board(Constants.Player.PLAYER_2)
	await get_tree().create_timer(1.0).timeout
	ai_player.make_combination()
	await get_tree().create_timer(1.0).timeout
	hide_combination_boards()
	await get_tree().create_timer(0.5).timeout
	game_state = Constants.GameState.PLACING
	ai_player.place_piece()
	#await get_tree().create_timer(0.5).timeout
	#end_turn()


func switch_player():
	current_player = Constants.Player.PLAYER_2 if current_player == Constants.Player.PLAYER_1 else Constants.Player.PLAYER_1


func determine_winner() -> WinResult:
	var player1_tiles = 0
	var player2_tiles = 0
				
	for cell in tile_map.get_used_cells(tile_map.BOARD_LAYER):
		var atlas_coords = tile_map.get_cell_atlas_coords(tile_map.BOARD_LAYER, cell)
		if atlas_coords == tile_map.PLAYER_1_TILE:
			player1_tiles += 1
		elif atlas_coords == tile_map.PLAYER_2_TILE:
			player2_tiles += 1

	if player1_tiles > player2_tiles:
		return WinResult.PLAYER_1_WIN
	elif player2_tiles > player1_tiles:
		return WinResult.PLAYER_2_WIN
	else:
		return WinResult.TIE
