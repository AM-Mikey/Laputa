extends Camera2D

const BLACKBAR = preload("res://src/Utility/BlackBar.tscn")




onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")

onready var player_pos = pc.global_position
onready var camera_pos = pc.get_node("PlayerCamera").get_camera_screen_center()

func _ready():
	add_to_group("Cameras")
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed") #TODO: err
	on_viewport_size_changed()
	
	global_position = camera_pos


func focus_player():
	$Tween.interpolate_property(self, "position", self.position, player_pos, 4, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()


func _on_limit_camera(left, right, top, bottom):
	var bars = get_tree().get_nodes_in_group("BlackBars")
	for b in bars:
		b.free()
	
	
	if  OS.get_window_size().x > (right - left) * world.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = ((OS.get_window_size().x / world.resolution_scale) - (right - left))/2
		
		limit_left = left - extra_margin
		limit_right = right + extra_margin
		
		var left_pillar = BLACKBAR.instance()
		left_pillar.name = "BlackBarLeft"
		left_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		world.get_node("UILayer").add_child(left_pillar)
		world.get_node("UILayer").move_child(left_pillar, 0)
		
		var right_pillar = BLACKBAR.instance()
		right_pillar.name = "BlackBarRight"
		right_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		right_pillar.rect_position = Vector2((right - left) + extra_margin, 0)
		world.get_node("UILayer").add_child(right_pillar)
		world.get_node("UILayer").move_child(right_pillar, 0)
		
	else:
		limit_left = left
		limit_right = right
	
	if OS.get_window_size().y > (bottom - top) * world.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (OS.get_window_size().y - (bottom - top))/2
		limit_top = top - extra_margin
		limit_bottom = bottom  + extra_margin
		
		var top_pillar = BLACKBAR.instance()
		top_pillar.name = "BlackBarTop"
		top_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		world.get_node("UILayer").add_child(top_pillar)
		world.get_node("UILayer").move_child(top_pillar, 0)
		
		var bottom_pillar = BLACKBAR.instance()
		bottom_pillar.name = "BlackBarRight"
		bottom_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		bottom_pillar.rect_position = Vector2(0, (bottom - top) + extra_margin)
		world.get_node("UILayer").add_child(bottom_pillar)
		world.get_node("UILayer").move_child(bottom_pillar, 0)
	
	else:
		limit_top = top
		limit_bottom = bottom



func on_viewport_size_changed():
	zoom = Vector2(1 / world.resolution_scale, 1 / world.resolution_scale)
