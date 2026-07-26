extends Node2D

var self_rect: Rect2 = Rect2()
var bod_rect: Rect2 = Rect2()
var over_rect: Rect2 = Rect2()

@onready var main = get_parent()

func _draw() -> void:
	if main:
		if main.name in main.debug_name:
			var draw_bod_rect = Rect2(bod_rect.position - global_position, bod_rect.size)
			var draw_self_rect = Rect2(self_rect.position - global_position, self_rect.size)
			var draw_over_rect = Rect2(over_rect.position - global_position, over_rect.size)
			draw_rect(draw_bod_rect, Color.BLUE)
			draw_rect(draw_self_rect, Color.RED)
			draw_rect(draw_over_rect, Color.PURPLE)
