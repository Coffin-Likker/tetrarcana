extends Control

signal menu_changed(new_menu_type)
signal menu_back

func change_menu(menu_type: MenuTypes.Type):
	emit_signal("menu_changed", menu_type)

func go_back():
	emit_signal("menu_back")
