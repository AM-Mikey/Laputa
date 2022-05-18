tool
extends Node2D

export var texture: StreamTexture setget on_texture_changed
export var hframe: int setget on_hframe_changed
export var back_vframe: int setget on_back_vframe_changed
export var front_vframe: int setget on_front_vframe_changed


onready var back = $Back#get_parent().get_node("Back")
onready var front = $Front#get_parent().get_node("Front")

func on_texture_changed(new_texture): #TODO, texture needs to be changed before frames
	back.texture = new_texture
	back.hframes = back.texture.get_width() /32
	back.vframes = back.texture.get_height() /32
	front.texture = new_texture
	front.hframes = back.texture.get_width() /32
	front.vframes = back.texture.get_height() /32


func on_hframe_changed(new_hframe):
	back.frame_coords.x = new_hframe
	front.frame_coords.x = new_hframe

func on_back_vframe_changed(new_vframe):
	if new_vframe == -1:
		back.texture = null
		back.frame_coords.y = 0
	else:
		back.frame_coords.y = new_vframe

func on_front_vframe_changed(new_vframe):
	if new_vframe == -1:
		front.texture = null
		front.frame_coords.y = 0
	else:
		front.frame_coords.y = new_vframe
