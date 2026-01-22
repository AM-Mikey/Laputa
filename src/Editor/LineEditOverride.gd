extends LineEdit

func _gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		if event.shift_pressed:
			insert_text_at_caret("C")
		else:
			insert_text_at_caret("c")
		accept_event()
