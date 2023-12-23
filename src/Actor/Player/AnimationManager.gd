extends Node

enum Layer {BACK, FRONT, BOTH}


@onready var pc = get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var ap = pc.get_node("AnimationPlayer")

@onready var sprite = pc.get_node("Sprite2D")
@onready var gun_manager = pc.get_node("GunManager")
@onready var guns = pc.get_node("GunManager/Guns")



var blend_array = [ #controls which animations should blend
	["run", "crouch_run", "back_run"],
	["stand"],
]

var gun_pos_dict = {

	"stand" : [
			{0: Vector2(-7,-12)},
			{0: Vector2(-3,-16)},
			{0: Vector2(-5,-7)},
			{0: Vector2(-7,-12)},
			{0: Vector2(1,-10)},
			{0: Vector2(-1,-16)},
			{0: Vector2(0,-7)},
			{0: Vector2(1,-10)},
			],
	"run" : [
			{0: Vector2(-7,-9), 3: Vector2(-6,-9), 4: Vector2(-5,-9), 9: Vector2(-6,-9), 10: Vector2(-7,-9)},
			{0: Vector2(-5,-16), 1: Vector2(-5,-14), 2: Vector2(-5,-15), 5: Vector2(-5,-14), 6: Vector2(-5,-13), 7: Vector2(-5,-11), 8: Vector2(-5,-12), 9: Vector2(-5,-14), 10: Vector2(-5,-16)},
			{0: Vector2(-3,-6), 1: Vector2(-3,-5), 2: Vector2(-3,-6), 4: Vector2(-3,-7), 6: Vector2(-3,-6), 7: Vector2(-3,-5), 8: Vector2(-3,-6), 10: Vector2(-3,-7)},
			{0: Vector2(-7,-9), 3: Vector2(-6,-9), 4: Vector2(-5,-9), 9: Vector2(-6,-9), 10: Vector2(-7,-9)},
			{0: Vector2(1,-9), 3: Vector2(2,-9), 4: Vector2(3,-9), 9: Vector2(2,-9), 10: Vector2(1,-9)},
			{0: Vector2(1,-13), 1: Vector2(1,-11), 2: Vector2(1,-12), 3: Vector2(1,-14), 4: Vector2(1,-16), 6: Vector2(1,-16), 7: Vector2(1,-14), 8: Vector2(1,-15), 11: Vector2(1,-14)},
			{0: Vector2(3,-6), 1: Vector2(3,-5), 2: Vector2(3,-6), 4: Vector2(3,-7), 6: Vector2(3,-6), 7: Vector2(3,-5), 8: Vector2(3,-6), 10: Vector2(3,-7)},
			{0: Vector2(1,-9), 3: Vector2(2,-9), 4: Vector2(3,-9), 9: Vector2(2,-9), 10: Vector2(1,-9)},
			],
	"crouch_run" : [
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(-5,-14), 1: Vector2(-5,-12), 2: Vector2(-5,-13), 5: Vector2(-5,-12), 6: Vector2(-5,-11), 7: Vector2(-5,-9), 8: Vector2(-5,-10), 9: Vector2(-5,-12), 10: Vector2(-5,-14)},
			{0: Vector2(-3,-4), 1: Vector2(-3,-3), 2: Vector2(-3,-4), 4: Vector2(-3,-5), 6: Vector2(-3,-4), 7: Vector2(-3,-3), 8: Vector2(-3,-4), 10: Vector2(-3,-5)},
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			{0: Vector2(1,-11), 1: Vector2(1,-9), 2: Vector2(1,-10), 3: Vector2(1,-12), 4: Vector2(1,-14), 6: Vector2(1,-14), 7: Vector2(1,-12), 8: Vector2(1,-13), 11: Vector2(1,-12)},
			{0: Vector2(3,-4), 1: Vector2(3,-3), 2: Vector2(3,-4), 4: Vector2(3,-5), 6: Vector2(3,-4), 7: Vector2(3,-3), 8: Vector2(3,-4), 10: Vector2(3,-5)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			],
	"aerial_rise" : [
			{0: Vector2(-7,-11)},
			{0: Vector2(-5,-16)},
			{0: Vector2(-7,-7)},
			{0: Vector2(3,-11)},
			{0: Vector2(5,-16)},
			{0: Vector2(2,-7)},
			],
	"aerial_top" : [
			{0: Vector2(-5,-11)},
			{0: Vector2(-3,-16)},
			{0: Vector2(-3,-6)},
			{0: Vector2(2,-11)},
			{0: Vector2(3,-16)},
			{0: Vector2(1,-7)},
			],
	"aerial_fall" : [
			{0: Vector2(-3,-11)},
			{0: Vector2(-1,-16)},
			{0: Vector2(0,-6)},
			{0: Vector2(0,-11)},
			{0: Vector2(1,-16)},
			{0: Vector2(0,-6)},
			],
	"back_run" : [
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(-5,-14), 1: Vector2(-5,-12), 2: Vector2(-5,-13), 5: Vector2(-5,-12), 6: Vector2(-5,-11), 7: Vector2(-5,-9), 8: Vector2(-5,-10), 9: Vector2(-5,-12), 10: Vector2(-5,-14)},
			{0: Vector2(-3,-4), 1: Vector2(-3,-3), 2: Vector2(-3,-4), 4: Vector2(-3,-5), 6: Vector2(-3,-4), 7: Vector2(-3,-3), 8: Vector2(-3,-4), 10: Vector2(-3,-5)},
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			{0: Vector2(1,-11), 1: Vector2(1,-9), 2: Vector2(1,-10), 3: Vector2(1,-12), 4: Vector2(1,-14), 6: Vector2(1,-14), 7: Vector2(1,-12), 8: Vector2(1,-13), 11: Vector2(1,-12)},
			{0: Vector2(3,-4), 1: Vector2(3,-3), 2: Vector2(3,-4), 4: Vector2(3,-5), 6: Vector2(3,-4), 7: Vector2(3,-3), 8: Vector2(3,-4), 10: Vector2(3,-5)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			],
}


func get_gun_pos(sheet_name: String, animation_index: int, frame_index: int) -> Vector2:
	var gun_pos = Vector2.ZERO
	var sheet_data = gun_pos_dict[sheet_name]
	
	var animation_data = sheet_data[animation_index]
	
	if animation_data.has(frame_index):
		gun_pos = animation_data[frame_index]
	else:
		var keys = animation_data.keys()
		for k in keys:
			if k < frame_index: #should find the highest frame lower than the frame index
				gun_pos = animation_data[k]
	
	return gun_pos


func set_gun_draw_index():
	var gun_index
	if guns.scale.x == 1:
		gun_index = sprite.get_index() - 1
	else: 
		gun_index = sprite.get_index() + 1
	get_parent().move_child(gun_manager, gun_index)
