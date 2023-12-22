extends Node

const YN = preload("res://src/Dialog/DialogYesNo.tscn")
const TBOX = preload("res://src/Dialog/TopicBox.tscn")

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var db = get_parent()

@onready var tb = db.get_node("Margin/HBox/RichTextBox")
@onready var face_sprite = db.get_node("Margin/HBox/Face/Sprite2D")

func parse_command(string):
	var command = string.split(",", true, 1)
	print("command: ", command)
	
	var function = command[0]
	var argument
	if command.size() > 1:
		argument = command[1]

	print("function: ", function)
	print("argument: ", argument)

	match function:
		"face":#				/face, (sprite_name) 									changes face_sprite to the specified file
			face(argument)
		"flip_face":
			flip_face(argument)
		"name":#				/name, (string)											prints a name on the first line
			display_name(argument)
		
		"hide":#				/hide, (string: npc_id)									makes the npc with given id invisible
			do_hide(argument)
		"walk":#				/walk, (string: npc_id), (int: distance)				makes an npc walk a certain distance from their current pos
			walk(argument)#																with negative being left and positive being right
		"yn":
			yes_no()
		"/db":
			end_branch()
		
		"lock":#																		disables and makes the player character invincible
			pc.disable()
		"focus":#					/focus, (string: npc_id)							focuses PlayerCamera on an npc, doesn't work indoors
			focus(argument)
		"unfocus":#																	returns camera focus to the pc
			unfocus()
		
		"left":#																		faces an npc left
			flip(Vector2.LEFT, argument)
		"right":#																		faces an npc right
			flip(Vector2.RIGHT, argument)

		
		"clear":#																		clears the text
			tb.text = ""
		"wait":#					/wait, (float: duration = 1.0)						clears text and hides db until duration
			wait(argument)
		
		"auto":#																		blocks input and automatically progresses text
			db.auto_input = true
		"pass":#																		automatically progresses the next line
			db.auto_input = true
			await get_tree().create_timer(0.1).timeout #a bad way of doing this
			db.auto_input = false
			
		"tbox":
			pc.disable()
			world.get_node("UILayer").add_child(TBOX.instantiate())





func seek(string):
	print("seeking: ", string)
	db.step = db.text.find(string, db.step)

func face(string):
	if string == "":
		printerr("COMMAND ERROR: no npc given for /face")
		return
	var face = string.split(",", true, 1)
	var id = face[0]
	var expression = 0
	if face.size() > 1:
		expression = int(face[1])
	
	face_sprite.texture = load("res://assets/UI/Face/%s" % id.capitalize() + ".png")
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
	
	var color = "white"
	var name_regex = RegEx.new()
	name_regex.compile("\\[b]\\[color=" + color + "].*\\[/color]\\[/b]")
	tb.text = name_regex.sub(tb.text, "")

	if string == "":
		printerr("COMMAND ERROR: no npc given for /name")
		return
	
	var display_name = string.capitalize() + ": "
	tb.text = "[b][color=" + color + "]" + display_name + "[/color][/b]" + tb.text
	
func do_hide(string):
	if string == "":
		printerr("COMMAND ERROR: no npc given for /hide")
		return
	var id = string.to_lower()
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			n.visible = false
	
func do_unhide(string):
	if string == "":
		printerr("COMMAND ERROR: no npc given for /unhide")
		return
	var id = string.to_lower()
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			n.visible = true

func walk(string):
	db.busy = true
	
	var walk = string.split(",", true, 1)
	var id = walk[0]
	var distance = int(walk[1])
	
	if walk[1] == null:
		printerr("COMMAND ERROR: not enough arguments for /walk")
		return
	
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			n.target_pos = Vector2(n.global_position.x + (distance * 16), 0)
			print("npc target position: ", n.target_pos)
			
			if n.global_position.x < n.target_pos.x: #npc to the left of target
				n.move_dir = Vector2.RIGHT
			if n.global_position.x > n.target_pos.x: #npc to the right of target
				n.move_dir= Vector2.LEFT
		
			n.move_to_target_x()

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
			match direction:
				Vector2.LEFT: n.get_node("Sprite2D").flip_h = false
				Vector2.RIGHT: n.get_node("Sprite2D").flip_h = true

	if found_npcs == 0:
		printerr("COMMAND ERROR: could not find NPC with id: " + id)
		

func wait(string):
	var wait_time = float(string) if string != null and float(string) != 0 else 1.0
	
	db.visible = false
	db.busy = true
	await get_tree().create_timer(wait_time).timeout
	
	db.visible = true
	db.busy = false
	tb.text = ""
	db.dialog_loop()
	print("finished waiting")

