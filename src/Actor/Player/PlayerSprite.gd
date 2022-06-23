tool
extends Sprite

export var hframe: int setget on_hframe_changed
#export var gun_pos: Vector2 setget on_gun_pos_changed
#export var gun_rot: int setget on_gun_rot_changed
#export var gun_flip_offset: int setget on_gun_flip_offset_changed


func on_hframe_changed(new_hframe):
	frame_coords.x = new_hframe

func _on_Sprite_texture_changed():
	hframes = texture.get_width() /32
	vframes = texture.get_height() /32

#func on_gun_flip_offset_changed(new_gun_flip_offset):
#	gun_flip_offset = new_gun_flip_offset
#func on_gun_rot_changed(new_gun_rot):
#	gun_rot = new_gun_rot
#func on_gun_pos_changed(new_gun_pos):
#	gun_pos = new_gun_pos

func _process(_delta):
	if get_parent() != null:
		if get_parent().has_node("GunSprite"):
			#get_parent().get_node("GunSprite").rotation_degrees = gun_rot
			
			if not get_parent().get_node("GunSprite").flip_h:
				#get_parent().get_node("GunSprite").position = gun_pos
				get_parent().get_node("GunSprite").z_index = -1
			else: 
				#get_parent().get_node("GunSprite").position = Vector2(gun_pos.x + gun_flip_offset, gun_pos.y)
				get_parent().get_node("GunSprite").z_index = 0
