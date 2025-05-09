extends LineEdit

func _gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		insert_text_at_caret("c")
		accept_event()
