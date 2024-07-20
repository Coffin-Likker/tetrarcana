extends TileMap

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_tile_clicked(event.position)

func _on_tile_clicked(click_position):
	var tile_position = local_to_map(to_local(click_position))
	var current_tile = get_cell_source_id(0, tile_position)
	
	# BAD YUCK (idk how to make tilesheets with just one tile yet)
	var green_tile_source_id = 0
	var green_tile_atlas_coords = Vector2i(16, 5)
	
	set_cell(0, tile_position, green_tile_source_id, green_tile_atlas_coords)
