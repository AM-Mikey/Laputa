tool
extends Sprite


func on_texture_changed():
# warning-ignore:integer_division
	hframes = texture.get_width() /32
# warning-ignore:integer_division
	vframes = texture.get_height() /32
