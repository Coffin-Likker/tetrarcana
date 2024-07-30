extends Node

var move_sounds: Array[AudioStreamPlayer] = []
var place_sounds: Dictionary = {}
var win_sounds: Dictionary = {}
var combine_sounds: Dictionary = {}
var cant_place_sound: AudioStreamPlayer
var current_sound_index: int = 0
var open_combo_sound : AudioStreamPlayer

func _ready():
	# Initialize move sounds
	for i in range(1, 11):
		var sound = AudioStreamPlayer.new()
		sound.stream = load("res://assets/audio/sequence/8bitmelody2_" + str(i) + ".wav")  # Adjust the path as needed
		sound.bus = AudioManager.SFX_BUS_NAME
		add_child(sound)
		move_sounds.append(sound)
	
	# Initialize place sounds
	var light_sound = AudioStreamPlayer.new()
	light_sound.stream = load("res://assets/audio/placing/LightPlacing(Short).wav")  # Adjust the path
	light_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(light_sound)
	place_sounds["light"] = light_sound
	
	var shadow_sound = AudioStreamPlayer.new()
	shadow_sound.stream = load("res://assets/audio/placing/ShadowPlacing(short).wav")  # Adjust the path
	shadow_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(shadow_sound)
	place_sounds["shadow"] = shadow_sound
	
	# Initialize win sounds
	var light_win_sound = AudioStreamPlayer.new()
	light_win_sound.stream = load("res://assets/audio/winning/LightWin.wav")  # Adjust the path
	light_win_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(light_win_sound)
	win_sounds["light"] = light_win_sound
	
	var shadow_win_sound = AudioStreamPlayer.new()
	shadow_win_sound.stream = load("res://assets/audio/winning/ShadowWin.wav")  # Adjust the path
	shadow_win_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(shadow_win_sound)
	win_sounds["shadow"] = shadow_win_sound
	
	# Initialize combine sounds
	var light_combine_sound = AudioStreamPlayer.new()
	light_combine_sound.stream = load("res://assets/audio/placing/LightCombining.wav")  # Adjust the path
	light_combine_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(light_combine_sound)
	combine_sounds["light"] = light_combine_sound
	
	var shadow_combine_sound = AudioStreamPlayer.new()
	shadow_combine_sound.stream = load("res://assets/audio/placing/ShadowCombining.wav")  # Adjust the path
	shadow_combine_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(shadow_combine_sound)
	combine_sounds["shadow"] = shadow_combine_sound
	
	# Initialize can't place sound
	cant_place_sound = AudioStreamPlayer.new()
	cant_place_sound.stream = load("res://assets/audio/placing/CannotPlaceError.wav")  # Adjust the path
	cant_place_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(cant_place_sound)
	
	open_combo_sound = AudioStreamPlayer.new()
	open_combo_sound.stream = load("res://assets/audio/misc/PaperScroll.wav")
	open_combo_sound.bus = AudioManager.SFX_BUS_NAME
	add_child(open_combo_sound)

func play_move_sound():
	if move_sounds.size() > 0:
		move_sounds[current_sound_index].play()
		current_sound_index = (current_sound_index + 1) % move_sounds.size()

func play_place_sound(player: String):
	if player in place_sounds:
		place_sounds[player].play()

func play_win_sound(player: String):
	if player in win_sounds:
		win_sounds[player].play()

func play_combine_sound(player: String):
	if player in combine_sounds:
		combine_sounds[player].play()
		
func play_parchment_sound():
	open_combo_sound.play()

func play_cant_place_sound():
	cant_place_sound.play()

# Function to play sound on rotation (same as move sound)
func play_rotation_sound():
	play_move_sound()
