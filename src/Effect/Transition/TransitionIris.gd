extends Control

var animation = "IrisContract"

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = f.pc()

func _ready():
		print("playing in animation")
		$AnimationPlayer.play(animation)


func play_out_animation():
	print("playing out animation")
	$AnimationPlayer.play(animation)


func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"IrisContract": animation = "IrisExpand"
		"IrisExpand":
			#print("free iris from itself")
			queue_free()


func _physics_process(_delta):
	var vp_size = RenderAlign.sub_viewport.size / vs.resolution_scale

	var cam = pc.get_node("PlayerCamera")
	if not cam.enabled:
		for l in get_tree().get_nodes_in_group("Levels"):
			cam = l.get_node("LevelCamera")


	var player_pos_from_cam_center = Vector2(pc.position.x, pc.position.y - 16) - cam.get_screen_center_position()
	var max_dist_from_vp = max(abs(player_pos_from_cam_center.x) + vp_size.x / 2, abs(player_pos_from_cam_center.y) + vp_size.y / 2)
	var nearest_multiple = ceil((max_dist_from_vp * 2) / 256) * 256 #round up to nearest 256 multiple
	$MarginContainer.size = Vector2(nearest_multiple, nearest_multiple)
	$MarginContainer.position = Vector2(vp_size.x - $MarginContainer.size.x, vp_size.y - $MarginContainer.size.y) / 2
	$MarginContainer.position += player_pos_from_cam_center
