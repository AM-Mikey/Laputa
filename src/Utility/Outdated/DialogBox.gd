extends Control

var prompt_sound = load("res://assets/SFX/snd_menu_prompt.ogg")
var move_sound = load("res://assets/SFX/snd_menu_move.ogg")
var select_sound = load("res://assets/SFX/snd_menu_select.ogg")

var connected_npc: Node

@onready var sb = $SyndiBox
@onready var player = get_tree().get_root().get_node("World/Juniper")


func _on_display_text(npc_path, display_name, face, expression, text, justify, voiced):
	connected_npc = get_node(npc_path)
	
	align_box()
	visible = true
	
	if face != "":
		$Face.texture = load("res://assets/UI/Face/%s" % face + ".png")
		$Face.hframes = $Face.texture.get_width()/48
		$Face.frame = expression
	
#	if voiced:
#		sb.TEXT_VOICE = "res://assets/SFX/snd_msg.ogg"
#	else:
#		sb.TEXT_VOICE = "null"
	justify_text(justify)
	
	if display_name != "":
		sb.start(String("[`c]" + display_name + ":  [`r]" + text))
	else:
		sb.start(text)

func _on_speed_text():
	sb.TEXT_SPEED = .005

func _on_stop_text():
	visible = false
	sb.stop()

func _on_show_branch(branch):
	print("branch: ", branch)
	print(int(branch))
	

	var branch_children = $DialogBranch.get_children()
	for c in branch_children:
		if c is Button:
			c.visible = false
	
	if "ta" in branch:
		$DialogBranch.get_node("Talk").visible = true
		$DialogBranch.get_node("Ask").visible = true
	
	if "yn" in branch:
		$DialogBranch.get_node("Yes").visible = true
		$DialogBranch.get_node("No").visible = true
		
	await sb.printing_finished
	$DialogBranch.visible = true
	if int(branch) != 1: 
		$DialogBranch.branch_id = String(int(branch))
	else: #1 is blank so its just y01 or n01
		$DialogBranch.branch_id = ""
	$Audio.stream = prompt_sound
	$Audio.play()
	
func _on_show_topic():
	await sb.printing_finished
	$DialogTopic.visible = true
	$Audio.stream = prompt_sound
	$Audio.play()
	
func err_expression(face, expression): #if expression is not found
	print("ERROR: face sprite of face '", face, "' with expression '", expression, "' not found")

func align_box():
	var player_pos = player.get_global_transform_with_canvas().get_origin() #dont ask why this works, but it does
	var part_viewport_height = (get_viewport().size.y)/6
	if player_pos.y > part_viewport_height:
		position.y = -160
	else:
		position.y = 0

func justify_text(justify):
	if justify == "Face":
		sb.offset_left = $FaceRect.offset_left
		sb.offset_right = $FaceRect.offset_right
		sb.offset_top = $FaceRect.offset_top
		sb.offset_bottom = $FaceRect.offset_bottom
		$Face.visible = true
	if justify == "NoFace":
		sb.offset_left = $NoFaceRect.offset_left
		sb.offset_right = $NoFaceRect.offset_right
		sb.offset_top = $NoFaceRect.offset_top
		sb.offset_bottom = $NoFaceRect.offset_bottom
		$Face.visible = false
	if justify == "NFCenter":
		sb.offset_left = $NoFaceRect.offset_left
		sb.offset_right = $NoFaceRect.offset_right
		sb.offset_top = $NoFaceRect.offset_top
		sb.offset_bottom = $NoFaceRect.offset_bottom
		$Face.visible = false
	#else:
		#print ("ERROR: no justification applied to text")


func _on_SyndiBox_text_finished():
	print("synd text finished")
	if connected_npc != null:
			connected_npc.talking = false


func _on_SyndiBox_section_finished(cur_section):
	print("synd section finished")
	if connected_npc != null:
		connected_npc.progress_dialog(connected_npc.conversation)


func _on_SyndiBox_printing_finished():
	pass # Replace with function body.
