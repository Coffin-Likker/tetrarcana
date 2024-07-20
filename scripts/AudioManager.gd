extends Node

const MASTER_BUS_NAME = "Master"
const MUSIC_BUS_NAME = "Music"
const SFX_BUS_NAME = "SFX"

var master_bus_index
var music_bus_index
var sfx_bus_index

signal volume_changed(bus_name, volume_db)

func _ready():
	master_bus_index = AudioServer.get_bus_index(MASTER_BUS_NAME)
	music_bus_index = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)

func set_volume_db(bus_name: String, volume_db: float):
	match bus_name:
		MASTER_BUS_NAME:
			AudioServer.set_bus_volume_db(master_bus_index, volume_db)
		MUSIC_BUS_NAME:
			AudioServer.set_bus_volume_db(music_bus_index, volume_db)
		SFX_BUS_NAME:
			AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)
	emit_signal("volume_changed", bus_name, volume_db)

func get_volume_db(bus_name: String) -> float:
	match bus_name:
		MASTER_BUS_NAME:
			return AudioServer.get_bus_volume_db(master_bus_index)
		MUSIC_BUS_NAME:
			return AudioServer.get_bus_volume_db(music_bus_index)
		SFX_BUS_NAME:
			return AudioServer.get_bus_volume_db(sfx_bus_index)
	return 0.0
