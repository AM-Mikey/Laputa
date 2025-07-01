extends Node #TODO: this script needs major cleanup

const YN = preload("res://src/Dialog/DialogYesNo.tscn")
const TBOX = preload("res://src/Dialog/TopicBox.tscn")

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var db = get_parent()

@onready var tb = db.get_node("Margin/HBox/RichTextBox")


func parse_command(string):
	var command = string.split(",", true, 1)
	print("command: ", string)
	
	var function = command[0]
	var argument
	if command.size() > 1:
		argument = command[1]

	#print("function: ", function)
	#print("argument: ", argument)

	match await function: #TODO: probably slow, replace this with something else
		"face":#				/face, (sprite_name) 									changes face_sprite to the specified file
			face(argument)
		"flipface":#			/flipface, (string: direction)							flips the face sprite, to the opposite direction, or in a specified direction
			flip_face(argument)
		"name":#				/name, (string)											prints a name on the first line
			display_name(argument)
		
		"hide":#				/hide, (string: npc_id)									makes the npc with given id invisible
			set_visible(argument, false)
		"unhide":
			set_visible(argument, true)
		
		"waypoint":#			/waypoint, (string: npc_id), (int: waypoint_index)
			waypoint(argument)
		#"walk":#				/walk, (string: npc_id), (int: distance)				makes an npc walk a certain distance from their current pos
			#walk(argument)#																with negative being left and positive being right
		#"yn":
			#yes_no()
		#"/db":
			#end_branch()
		#"lock":#																		disables and makes the player character invincible
			#pc.disable()
		#"focus":#					/focus, (string: npc_id)							focuses PlayerCamera on an npc, doesn't work indoors
			#focus(argument)
		#"unfocus":#																		returns camera focus to the pc
			#unfocus()
		
		"lookat":#					/lookat, (string: npc_id), (string: target_npc_id) or ("player" or "pc")
			lookat(argument)
		"left":#					/left, (string: npc_id)								faces an npc left
			flip("left", argument)
		"right":#					/right, (string: npc_id)							faces an npc right
			flip("right", argument)
		
		"clear":#																		clears the text		(use at start of text)
			tb.text = ""
		"wait":#					/wait, (float: duration = 1.0)						clears text and hides db until duration
			await wait(argument)
		"auto":#																		blocks input and automatically progresses text
			if argument == "on":
				db.auto_input = true
				db.do_delay = true
			else:
				db.auto_input = false
		"skipinput":#																		automatically progresses the next line
			skipinput()
			
		#"tbox":
			#pc.disable()
			#world.get_node("UILayer").add_child(TBOX.instantiate())
	
	


### COMMANDS ###

func face(string):
	var no_face_spacer = db.get_node("Margin/HBox/NoFaceSpacer")
	var face_node = db.get_node("Margin/HBox/Face")
	var face_sprite = face_node.get_node("Sprite2D")
	
	if string == "":
		printerr("COMMAND ERROR: no npc given for /face")
		return
	var face = string.split(",", true, 1)
	var id =  face[0]
	var expression = 0
	if face.size() > 1:
		expression = int(face[1])
	
	no_face_spacer.visible = false
	face_node.visible = true
	
	face_sprite.texture = load("res://assets/Face/%s.png" % id.capitalize())
	face_sprite.hframes = face_sprite.texture.get_width() / 48
	face_sprite.frame = expression
	
	var tween = get_tree().create_tween()
	tween.tween_property(face_sprite, "position", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func flip_face(arguement):
	if not arguement:
		db.flip_face()
	else:
		db.flip_face(arguement)

func display_name(string):
	tb.text = "" #clear text for new speaker
	
	var color = "goldenrod"
	var name_regex = RegEx.new()
	name_regex.compile("\\[b]\\[color=" + color + "].*\\[/color]\\[/b]")
	tb.text = name_regex.sub(tb.text, "")

	if string == "":
		printerr("COMMAND ERROR: no npc given for /name")
		return
	
	var display_name = string.capitalize() + ": "
	tb.text = "[b][color=" + color + "]" + display_name + "[/color][/b]" + tb.text
	
	
func set_visible(string, visible):
	if string == "":
		printerr("COMMAND ERROR: no npc given for /hide or /unhide")
		return
	var id = string.to_lower()
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			n.visible = visible

#func walk(string):
	#db.busy = true
	#
	#var walk = string.split(",", true, 1)
	#var id = walk[0]
	#var distance = int(walk[1])
	#
	#if walk[1] == null:
		#printerr("COMMAND ERROR: not enough arguments for /walk")
		#return
	#
	#for n in get_tree().get_nodes_in_group("NPCs"):
		#if n.id == id:
			#n.target_pos = Vector2(n.global_position.x + (distance * 16), 0)
			#print("npc target position: ", n.target_pos)
			#
			#if n.global_position.x < n.target_pos.x: #npc to the left of target
				#n.move_dir = Vector2.RIGHT
			#if n.global_position.x > n.target_pos.x: #npc to the right of target
				#n.move_dir= Vector2.LEFT
		#
			#n.move_to_target_x()

func waypoint(string):
	var a = string.split(",")
	var id = a[0]
	var index = int(a[1])
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			n.walk_to_waypoint(index)

func yes_no():
	db.busy = true
	var yn = YN.instantiate()
	add_child(yn)
	
	yn.get_node("MarginContainer/HBoxContainer/Yes").connect("pressed", Callable(self, "on_select_branch").bind("dba"))
	yn.get_node("MarginContainer/HBoxContainer/No").connect("pressed", Callable(self, "on_select_branch").bind("dbb"))

func on_select_branch(branch):
	if branch != null:
		seek("/" + branch)
		
	print("adding extra newline") #inserting newlines like this bypasses the input_event() line check, so add that code here
	tb.text += "\n"
	db.busy = false
	if tb.get_line_count() > 3: #was greater than or equal to, made starting on line 3 impossible
		tb.text = ""
	db.dialog_loop()


func end_branch():
	db.active = false
	db.flash_cursor()
	print("adding back newline")
	tb.text += "\n"
	seek("/m")
	db.step -= 3 #5 it changed #WHY WHY WHY WHY WHY #this is probably the cause of the step number going out of sync
	#we should hope to eliminate steps alltogether


func focus(string):
	if string == "":
		printerr("COMMAND ERROR: no npc given for /focus")
		return
	var id = string.to_lower()
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			pc.get_node("PlayerCamera").global_position = n.global_position


func unfocus():
	pc.get_node("PlayerCamera").position = Vector2.ZERO


func flip(direction, string):
	var id = string.to_lower()
	var found_npcs = 0
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			found_npcs += 1
			n.get_node("Sprite2D").flip_h = direction == "right"
	if found_npcs == 0:
		printerr("COMMAND ERROR: could not find NPC with id: " + id)


func lookat(string): #TODO: enable multiple lookers
	var a = string.split(",")
	var npc_id = a[0].to_lower()
	var target_id = a[1].to_lower()
	
	var found_npcs = []
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == npc_id:
			found_npcs.append(n)
	if found_npcs.is_empty():
		printerr("COMMAND ERROR: could not find NPC with id: " + npc_id)
		return
	
	var found_target = Node
	if target_id == "player" or target_id == "pc":
		found_target = pc
	else:
		for n in get_tree().get_nodes_in_group("NPCs"):
			if n.id == target_id:
				found_target = n
		if found_target == null:
			printerr("COMMAND ERROR: could not find NPC with id: " + target_id)
			return
	
	for n in found_npcs: #only looks at last n
		n.look_at_node(found_target)
	



func wait(string):
	var wait_time = float(string) if string != null and float(string) > 0 else 1.0
	db.busy = true
	await get_tree().create_timer(wait_time).timeout
	db.busy = false

func skipinput():
	db.auto_input = true
	db.do_delay = true
	await get_tree().create_timer(0.1).timeout
	db.auto_input = false



### HELPERS ###

func seek(string):
	print("seeking: ", string)
	db.step = db.text.find(string, db.step)
