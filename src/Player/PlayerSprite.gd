@tool
extends Sprite2D

@export var hframe: int: set = on_hframe_changed
var gun_pos_offset: Vector2 = Vector2.ZERO

func on_hframe_changed(new_hframe):
	frame_coords.x = new_hframe

func _on_Sprite_texture_changed():
	if Engine.is_editor_hint():
		hframes = int(texture.get_width() / 32.0)
		vframes = int(texture.get_height() / 32.0)


func set_gun_pos():
	var gun_manager = get_parent().get_node("GunManager")
	var guns = get_parent().get_node("GunManager/Guns")
	if guns == null:
		return
	
	var left = get_parent().get_node("GunManager/GunPosLeft")
	var left_up = get_parent().get_node("GunManager/GunPosLeftUp")
	var left_down = get_parent().get_node("GunManager/GunPosLeftDown")
	var right = get_parent().get_node("GunManager/GunPosRight")
	var right_up = get_parent().get_node("GunManager/GunPosRightUp")
	var right_down = get_parent().get_node("GunManager/GunPosRightDown")
	
	var gun_index = 0
	
	if vframes == 8:
		match frame_coords.y:
			0,3:
				guns.global_position = left.global_position
				guns.scale.x = 1.0
				guns.rotation_degrees = 0.0
				gun_index = -1
			1:
				guns.global_position = left_up.global_position
				guns.scale.x = 1.0
				guns.rotation_degrees = 90.0
				gun_index = -1
			2:
				guns.global_position = left_down.global_position
				guns.scale.x = 1.0
				guns.rotation_degrees = -90.0
				gun_index = 1 #over instead of under for the feet
			4,7:
				guns.global_position = right.global_position
				guns.scale.x = -1.0
				guns.rotation_degrees = 0.0
				gun_index = 1
			5:
				guns.global_position = right_up.global_position
				guns.scale.x = -1.0
				guns.rotation_degrees = -90.0
				gun_index = 1
			6:
				guns.global_position = right_down.global_position
				guns.scale.x = -1.0
				guns.rotation_degrees = 90.0
				gun_index = 1
	elif vframes == 6:
		match frame_coords.y:
			0:
				guns.global_position = left.global_position
				guns.scale.x = 1.0
				guns.rotation_degrees = 0.0
				gun_index = -1
			1:
				guns.global_position = left_up.global_position
				guns.scale.x = 1.0
				guns.rotation_degrees = 90.0
				gun_index = -1
			2:
				guns.global_position = left_down.global_position
				guns.scale.x = 1.0
				guns.rotation_degrees = -90.0
				gun_index = 1 #over instead of under for the feet
			3:
				guns.global_position = right.global_position
				guns.scale.x = -1.0
				guns.rotation_degrees = 0.0
				gun_index = 1
			4:
				guns.global_position = right_up.global_position
				guns.scale.x = -1.0
				guns.rotation_degrees = -90.0
				gun_index = 1
			5:
				guns.global_position = right_down.global_position
				guns.scale.x = -1.0
				guns.rotation_degrees = 90.0
				gun_index = 1
	
	guns.global_position += gun_pos_offset
	
	if not Engine.is_editor_hint():
		gun_index += get_index()
		get_parent().move_child.call_deferred(gun_manager, gun_index)
