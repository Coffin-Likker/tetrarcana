extends Control


@onready var master_slider = $OptionsVBox/MasterVolume/MasterHSlider
@onready var music_slider = $OptionsVBox/MusicVolume/MusicSlider
@onready var sfx_slider = $OptionsVBox/SFXVolume/HSlider


signal go_back


func _ready():
	master_slider.value = db_to_linear(AudioManager.get_volume_db(AudioManager.MASTER_BUS_NAME))
	music_slider.value = db_to_linear(AudioManager.get_volume_db(AudioManager.MUSIC_BUS_NAME))
	sfx_slider.value = db_to_linear(AudioManager.get_volume_db(AudioManager.SFX_BUS_NAME))
	
	AudioManager.connect("volume_changed", Callable(self, "_on_volume_changed"))


func _on_back_pressed():
	go_back.emit()


func _on_master_volume_changed(value):
	AudioManager.set_volume_db(AudioManager.MASTER_BUS_NAME, linear_to_db(value))


func _on_music_volume_changed(value):
	AudioManager.set_volume_db(AudioManager.MUSIC_BUS_NAME, linear_to_db(value))


func _on_sfx_volume_changed(value):
	AudioManager.set_volume_db(AudioManager.SFX_BUS_NAME, linear_to_db(value))


func _on_volume_changed(bus_name, volume_db):
	match bus_name:
		AudioManager.MASTER_BUS_NAME:
			master_slider.value = db_to_linear(volume_db)
		AudioManager.MUSIC_BUS_NAME:
			music_slider.value = db_to_linear(volume_db)
		AudioManager.SFX_BUS_NAME:
			sfx_slider.value = db_to_linear(volume_db)
