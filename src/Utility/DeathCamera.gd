extends Camera2D

const BLACKBAR = preload("res://src/Utility/BlackBar.tscn")




@onready var world = get_tree().get_root().get_node("World")
@onready var pc = f.pc()

@onready var player_pos = pc.global_position
@onready var camera_pos = pc.get_node("PlayerCamera").get_screen_center_position()

func _ready():
	global_position = camera_pos
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


func focus_player():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", player_pos, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func on_limit_camera(left, right, top, bottom):
	var bars = get_tree().get_nodes_in_group("BlackBars")
	for b in bars:
		b.free()


	if  get_window().get_size().x > (right - left) * vs.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = ((get_window().get_size().x / vs.resolution_scale) - (right - left))/2

		limit_left = left - extra_margin
		limit_right = right + extra_margin

		var left_pillar = BLACKBAR.instantiate()
		left_pillar.name = "BlackBarLeft"
		left_pillar.size = Vector2(extra_margin, get_window().get_size().y)
		world.bl.add_child(left_pillar)
		world.bl.move_child(left_pillar, 0)

		var right_pillar = BLACKBAR.instantiate()
		right_pillar.name = "BlackBarRight"
		right_pillar.size = Vector2(extra_margin, get_window().get_size().y)
		right_pillar.position = Vector2((right - left) + extra_margin, 0)
		world.bl.add_child(right_pillar)
		world.bl.move_child(right_pillar, 0)

	else:
		limit_left = left
		limit_right = right

	if get_window().get_size().y > (bottom - top) * vs.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (get_window().get_size().y - (bottom - top))/2
		limit_top = top - extra_margin
		limit_bottom = bottom  + extra_margin

		var top_pillar = BLACKBAR.instantiate()
		top_pillar.name = "BlackBarTop"
		top_pillar.size = Vector2(get_window().get_size().x, extra_margin)
		world.bl.add_child(top_pillar)
		world.bl.move_child(top_pillar, 0)

		var bottom_pillar = BLACKBAR.instantiate()
		bottom_pillar.name = "BlackBarRight"
		bottom_pillar.size = Vector2(get_window().get_size().x, extra_margin + 16) #16 for overscan safety
		bottom_pillar.position = Vector2(0, (bottom - top) + extra_margin)
		world.bl.add_child(bottom_pillar)
		world.bl.move_child(bottom_pillar, 0)

	else:
		limit_top = top
		limit_bottom = bottom



func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
