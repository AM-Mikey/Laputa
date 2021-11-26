tool
extends Sprite


func on_texture_changed():
	hframes = texture.get_width() /32
	vframes = texture.get_height() /32
