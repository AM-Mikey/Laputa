extends LineEdit

func _gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		if is_editing():
			if event.ctrl_pressed:
				if has_selection():
					DisplayServer.clipboard_set(get_selected_text())
			else:
				if has_selection():
					var from := get_selection_from_column()
					var length := get_selection_to_column() - from
					text = text.erase(from, length)
					caret_column = from
				if event.shift_pressed:
					insert_text_at_caret("C")
				else:
					insert_text_at_caret("c")
			accept_event()
