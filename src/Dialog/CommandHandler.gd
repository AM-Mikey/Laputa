extends Node #TODO: this script needs major cleanup

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var db = get_parent()



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
		#/face, (sprite_name)
		#changes face_sprite to the specified file
		"face":
			face(argument)
		#/flipface, (string: direction)
		#flips the face sprite, to the opposite direction, or in a specified direction
		"flipface":
			flip_face(argument)
		#/name, (string)
		"name":
			if argument == "":
				printerr("COMMAND ERROR: no npc given for /name")
				return
			db.display_name(argument)
		"hidename":
			db.hide_name()
		"newchar": #/newchar, (face), (name)
			var a = string.split(",")
			db.dl.text = ""
			face(a[1].to_lower())
			db.display_name( a[2].to_lower())
		"hide":#				/hide, (string: npc_id)									makes the npc with given id invisible
			set_visible(argument, false)
		"unhide":
			set_visible(argument, true)
		
		"waypoint":#			/waypoint, (string: npc_id), (int: waypoint_index)
			waypoint(argument)
		"impactline": #adds a center line for impact
			db.dl.text += "\n"
			#dl.horizontal_alignment = 1 #center
		"b":
			db.dl.text += " [b]"
		"ub": #doesnt work at end of line
			db.dl.text += "[/b] "
		"knockpc":
			var a = string.split(",")
			db.dl.text = ""
			match a[1]:
				"left": pc.mm.knockback_direction = Vector2.LEFT
				"right": pc.mm.knockback_direction = Vector2.RIGHT
			pc.mm.knockback_speed = Vector2(25, 40)
			pc.mm.snap_vector = Vector2.ZERO
			pc.mm.change_state("knockback")
		
		#"walk":#				/walk, (string: npc_id), (int: distance)				makes an npc walk a certain distance from their current pos
			#walk(argument)#																with negative being left and positive being right
		"yn":
			yes_no()
		"udb":
			end_branch()
		"options":
			options(argument)
		"topics":
			topics(argument)
		
		"t": 
			db.dl.text += " [b][color=#f3b131]" #bright gold
			if !pc.topic_array.has(argument):
				pc.topic_array.append(argument)
		"ut":
			db.dl.text += "[/color][/b] "
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
			db.dl.text = ""
		"wait":#					/wait, (float: duration = 1.0)						clears text and hides db until duration
			await wait(argument)
		"auto":#																		blocks input and automatically progresses text
			if argument == "on":
				db.auto_input = true
				db.do_delay = true
			else:
				db.auto_input = false
		"skipinput":#																		automatically progresses the next line
			pass
			#skipinput()


### COMMANDS ###

func face(string):
	var face_node = db.get_node("Face")
	var face_sprite = face_node.get_node("Sprite2D")
	
	if string == "":
		printerr("COMMAND ERROR: no npc given for /face")
		return
	var face = string.split(",", true, 1)
	var id =  face[0]
	var expression = 0
	if face.size() > 1:
		expression = int(face[1])
	
	face_node.visible = true
	
	face_sprite.texture = load("res://assets/Face/%s.png" % id.capitalize())
	face_sprite.hframes = face_sprite.texture.get_width() / 48
	face_sprite.frame = expression
	
	face_sprite.position.x = -48
	var tween = get_tree().create_tween()
	tween.tween_property(face_sprite, "position", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func flip_face(arguement):
	if not arguement:
		db.flip_face()
	else:
		db.flip_face(arguement)


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

#func skipinput():
	#db.auto_input = true
	#db.do_delay = true
	#await get_tree().create_timer(0.1).timeout
	#db.auto_input = false



### BRANCHING ###

func yes_no():
	db.get_node("Options").options = ["Yes", "No"]
	db.get_node("Options").display_options()
	db.dl = db.get_node("Response/DialogResponse")
	db.dl.text = ""
	if db.current_text_array[db.step + 3].begins_with("/db"): #if we see a /db ahead
		db.get_node("Options").exit_action = "options"

func options(string):
	var a = string.split(",")
	var capitalized_array = []
	for s in a:
		var capitalized = s.capitalize()
		capitalized_array.append(capitalized)
	db.get_node("Options").options = capitalized_array
	db.get_node("Options").display_options()
	db.dl = db.get_node("Response/DialogResponse")
	db.dl.text = ""
	if db.current_text_array[db.step + 3].begins_with("/db"): #if we see a /db ahead
		db.get_node("Options").exit_action = "options"

func topics(argument):
	var npc_topics = argument.split(",")
	var cap_pc_topics = []
	for topic in pc.topic_array:
		cap_pc_topics.append(topic.capitalize())
	var cap_npc_topics = []
	for topic in npc_topics:
		cap_npc_topics.append(topic.capitalize())
	var final_topics = []
	var final_ids = []
	for npc_topic in cap_npc_topics:
		for pc_topic in cap_pc_topics:
			if npc_topic == pc_topic:
				final_topics.append(npc_topic)
	for topic in final_topics:
		final_ids.append(cap_npc_topics.find(topic))

	db.get_node("Options").options = final_topics
	db.get_node("Options").ids = final_ids
	db.get_node("Options").display_options()
	db.dl = db.get_node("Response/DialogResponse")
	db.dl.text = ""
	if db.current_text_array[db.step + 3].begins_with("/db"): #if we see a /db ahead
		db.get_node("Options").exit_action = "topics"


func on_select_branch(branch):
	if branch != null:
		var seek_target = String("/db," + str(branch))
		seek(seek_target)


func end_branch():
	db.awaiting_merge = true
	db.flash_type = db.FLASH_NORMAL
	db.flash_original_text = db.dl.text
	db.get_node("FlashTimer").start(0.3)



func seek(string, do_nl = false):
	print("seeking: ", string)
	#print(db.current_text_array)
	var found = false
	for i in db.current_text_array:
		if i == string:
			found = true
			print(db.current_text_array.find(i))
			db.step = db.current_text_array.find(i) #to skip the null /db command
			db.progress_text(do_nl)
	if !found:
		printerr("ERROR: Branch " + string + " Not Found")
