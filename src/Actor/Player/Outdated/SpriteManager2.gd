tool
extends Node2D

export var texture: StreamTexture setget on_texture_changed
export var hframe: int setget on_hframe_changed
#export var back_vframe: int setget on_back_vframe_changed
#export var middle_vframe: int setget on_middle_vframe_changed
#export var front_vframe: int setget on_front_vframe_changed


onready var back = $Back
onready var middle = $Middle
onready var front = $Front

onready var sprites = [back, middle, front]

func on_texture_changed(new_texture): #TODO, texture needs to be changed before frames
	for s in sprites:
		s.texture = new_texture
		s.hframes = s.texture.get_width() /32
		s.vframes = s.texture.get_height() /32


func on_hframe_changed(new_hframe):
	back.frame_coords = Vector2(new_hframe, 0)
	middle.frame_coords = Vector2(new_hframe, 1)
	front.frame_coords = Vector2(new_hframe, 2)

#func on_back_vframe_changed(new_vframe):
#	if new_vframe == -1:
#		back.texture = null
#		back.frame_coords.y = 0
#	else:
#		back.frame_coords.y = new_vframe
#
#func on_middle_vframe_changed(new_vframe):
#	if new_vframe == -1:
#		middle.texture = null
#		middle.frame_coords.y = 0
#	else:
#		middle.frame_coords.y = new_vframe
#
#func on_front_vframe_changed(new_vframe):
#	if new_vframe == -1:
#		front.texture = null
#		front.frame_coords.y = 0
#	else:
#		front.frame_coords.y = new_vframe
