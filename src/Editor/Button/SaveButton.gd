extends MarginContainer

signal target_saved(save_target)

var save_target: String

func on_pressed():
	emit_signal("target_saved", save_target)
