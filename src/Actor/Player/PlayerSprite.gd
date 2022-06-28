tool
extends Sprite

export var hframe: int setget on_hframe_changed

func on_hframe_changed(new_hframe):
	frame_coords.x = new_hframe

func _on_Sprite_texture_changed():
	hframes = texture.get_width() /32
	vframes = texture.get_height() /32

func _process(_delta):
	if get_parent() != null:
		if get_parent().has_node("GunSprite"):
			var gun_index
			
			if not get_parent().get_node("GunSprite").flip_h:
				gun_index = get_index() - 1
			else: 
				gun_index = get_index() + 1
			
			var gun_sprite = get_parent().get_node("GunSprite")
			get_parent().move_child(gun_sprite, gun_index)
