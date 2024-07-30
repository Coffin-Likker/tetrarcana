extends Node

var move_sounds: Array[AudioStreamPlayer] = []
var place_sounds: Dictionary = {}
var current_sound_index: int = 0

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

func play_move_sound():
	if move_sounds.size() > 0:
		move_sounds[current_sound_index].play()
		current_sound_index = (current_sound_index + 1) % move_sounds.size()

func play_place_sound(player: String):
	if player in place_sounds:
		place_sounds[player].play()

# Function to play sound on rotation (same as move sound)
func play_rotation_sound():
	play_move_sound()
