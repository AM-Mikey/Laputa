extends Control

signal dialog_finished

const YN = preload("res://src/Dialog/DialogYesNo.tscn")

var text_sound = load("res://assets/SFX/Placeholder/snd_msg.ogg")

var prompt_sound = load("res://assets/SFX/Placeholder/snd_menu_prompt.ogg")
var move_sound = load("res://assets/SFX/Placeholder/snd_menu_move.ogg")
var select_sound = load("res://assets/SFX/Placeholder/snd_menu_select.ogg")


#export (String, FILE, "*.json") var dialog_json: String #we're passing this instead of setting

var dialog
var conversation: String
var text

export var print_delay = 0.05
export var do_delay = true
export var punctuation_delay = 0.3
var in_dialog = false
var active = true
var busy = false
#var completed = false


var step: int = 0 #step in printing dialog		

onready var tb = $MarginContainer/HBoxContainer/RichTextBox
onready var face_container = $MarginContainer/HBoxContainer/Face
onready var face_sprite = $MarginContainer/HBoxContainer/Face/Sprite
onready var audio = $AudioStreamPlayer


onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")

func _ready():
	visible = false
	get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()

func print_sign():
	face_container.free()
	tb.bbcode_text = "[b][center]" + text
	visible = true

func start_printing(dialog_json, npc_convo):
	audio.stream = text_sound
	tb.bbcode_text = ""
	visible = true
	in_dialog = true
	
	dialog = load_dialog(dialog_json)
	conversation = npc_convo
	
	text = dialog[conversation].strip_edges().replace("\t", "") #.json_escape() ## strip edges to clean up first and last newlines ### remove tabulation
	
	print(text)
	
	dialog_loop()

func dialog_loop():
	if not busy:
		while step < text.length(): #not completed: 
			print_dialog(text)
			step +=1
			if do_delay:
				if $PrintTimer.is_stopped():
					$PrintTimer.start(print_delay)
				yield($PrintTimer, "timeout")
			if not active:
				break
			if busy:
				break

func flash_cursor():
	yield(get_tree().create_timer(0.3), "timeout")
	print("flashing cursor")
	var added_text = tb.bbcode_text + "§"
	var deleted_text = tb.bbcode_text
	
	while active == false:
		tb.bbcode_text = added_text
		yield(get_tree().create_timer(0.3), "timeout")
		if active:
			break
		tb.bbcode_text = deleted_text
		yield(get_tree().create_timer(0.3), "timeout")

func remove_cursor():
	var cursor_position = tb.bbcode_text.rfind("§")
	if cursor_position != -1:
		var removed_cursor = tb.bbcode_text
		removed_cursor.erase(cursor_position, 1)
		tb.bbcode_text = removed_cursor

func _input(event):
	if event.is_action_pressed("inspect"):
		if in_dialog:
			if step >= text.length():
				print("reached end")
				stop_printing()
			
			if not active:
				do_delay = true
				#print_delay = default_print_delay
				active = true
				remove_cursor()
				
				print("adding back newline")
				tb.bbcode_text += "\n"
				
				if tb.get_line_count() > 3: #was greater than or equal to, made starting on line 3 impossible
					tb.bbcode_text = ""
				dialog_loop()
			
			else: #active
				do_delay = false
				#print_delay = 0.0


func load_dialog(dialog_json) -> Dictionary: #loads json and converts it into a dictionary
	var file = File.new()
	file.open(dialog_json, file.READ)
	
	var loaded_text = file.get_as_text()
	var loaded_dialog = JSON.parse(loaded_text).result
	return loaded_dialog


func print_dialog(string):
	if tb.get_line_count() == 4: #failsafe for if we overflow
		tb.remove_line(1)
		#tb.lines_skipped = 1
	#else:
		#tb.lines_skipped = 0
	
	var character = string.substr(step, 1)
	
	if character == ",": #or character == "." or character == "?" or character == "!": ##leave out other punctuation since the pause after a line is bad UX
		print("pausing for punctuation")
		$PrintTimer.stop()
		$PrintTimer.start($PrintTimer.time_left + punctuation_delay)
		print("insterted char: ", character)
		tb.bbcode_text += character
	
#	elif character == "\\": #this just looks for literal "\"
#		print("skipping escape char")
#		#step += 1
#		character = #string.substr(step, 1)
#		if character == "n":
#			active = false
#			flash_cursor()
#			print("adding back newline")
#			tb.bbcode_text += "\n"
#
	elif character == "\n":
		print("skipping newline")
		active = false
		flash_cursor()


	elif character == "/":
		var command = string.substr(step, -1)
		var first_space = command.find(" ")
		var first_newline = command.find("\n")
		
		if first_space < first_newline: #the space came first
			command = command.left(first_space)
		elif first_space > first_newline: #the newline came first
			command = command.left(first_newline)
		
		
		print("doing command: ", command)
		parse_command(command)
		step += command.length()
		
	else:
		print("step " + str(step) + " : " + character)
		tb.bbcode_text += character
		audio.play()


func stop_printing():
	print("ended dialog")
	emit_signal("dialog_finished")
	pc.get_node("PlayerCamera").position = Vector2.ZERO
	pc.disabled = false
	pc.invincible = false
	queue_free()

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
		"/face":
			face(argument)
		"/name":
			display_name(argument)
		"/hide":
			do_hide(argument)
		"/walk":
			walk(argument)
		"/yn":
			yes_no()
		"//db":
			end_branch()
		"/lock":
			pc.disabled = true
			pc.invincible = true
		"/focus":
			focus(argument)
		"/unfocus":
			unfocus()
		"/turn":
			turn(argument)


func seek(string):
	print("seeking: ", string)
	step = text.find(string, step)

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

func display_name(string):
	var name_regex = RegEx.new()
	name_regex.compile("\\[b]\\[color=red].*\\[/color]\\[/b]")
	tb.bbcode_text = name_regex.sub(tb.bbcode_text, "")

	if string == "":
		printerr("COMMAND ERROR: no npc given for /name")
		return
	
	var display_name = string.capitalize() + ": "
	tb.bbcode_text = "[b][color=red]" + display_name + "[/color][/b]" + tb.bbcode_text
	
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
	busy = true
	
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
	busy = true
	var yn = YN.instance()
	add_child(yn)
	
	yn.get_node("MarginContainer/HBoxContainer/Yes").connect("pressed", self, "on_select_branch", ["dba"])
	yn.get_node("MarginContainer/HBoxContainer/No").connect("pressed", self, "on_select_branch", ["dbb"])

func on_select_branch(branch):
	if branch != null:
		seek("/" + branch)
		
	print("adding extra newline") #inserting newlines like this bypasses the input_event() line check, so add that code here
	tb.bbcode_text += "\n"
	busy = false
	if tb.get_line_count() > 3: #was greater than or equal to, made starting on line 3 impossible
		tb.bbcode_text = ""
	dialog_loop()


func end_branch():
	active = false
	flash_cursor()
	print("adding back newline")
	tb.bbcode_text += "\n"
	seek("/m")
	step -= 3 #5 it changed #WHY WHY WHY WHY WHY #this is probably the cause of the step number going out of sync
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


func turn(string):
	var turn = string.split(",", true, 1)
	var id = turn[0]
	var direction = turn[1].capitalize()
	
	if turn[1] == null:
		printerr("COMMAND ERROR: not enough arguments for /turn")
		return
	
	var found_npcs = 0
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.id == id:
			found_npcs += 1
			var ap = n.get_node("AnimationPlayer")
			var animation = ap.current_animation.trim_suffix("Left") if "Left" in ap.current_animation else ap.current_animation.trim_suffix("Right") 
			
			if direction == "Left" or direction == "Right":
				ap.play(animation + direction)
		
			elif direction == "Player":
				match int(sign(pc.global_position.x - n.global_position.x)):
					-1: direction = "Left"
					1: direction = "Right"
				ap.play(animation + direction)
			
			else:
				printerr("COMMAND ERROR: invalid direction for /turn")

	if found_npcs == 0:
		printerr("COMMAND ERROR: could not find NPC with id: " + id)


func on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	#rect_size = get_tree().get_root().size / world.resolution_scale
	rect_size.x = viewport_size.x
	rect_position.y = viewport_size.y - 80
