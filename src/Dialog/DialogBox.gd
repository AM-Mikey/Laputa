extends Control

var text_sound = load("res://assets/SFX/snd_msg.ogg")

var prompt_sound = load("res://assets/SFX/snd_menu_prompt.ogg")
var move_sound = load("res://assets/SFX/snd_menu_move.ogg")
var select_sound = load("res://assets/SFX/snd_menu_select.ogg")


export (String, FILE, "*.json") var dialog_json: String

var dialog
var conversation: String
var text

var starting_line: int = 1 #unused
var ending_line: int # unused

export var print_delay = 0.05
export var punctuation_delay = 0.3
var in_dialog = false
var active = true
var busy = false


var step: int = 0 #step in printing dialog

onready var tb = $MarginContainer/HBoxContainer/TextBox
onready var face_container = $MarginContainer/HBoxContainer/Face
onready var face_sprite = $MarginContainer/HBoxContainer/Face/Sprite
onready var audio = $AudioStreamPlayer
onready var player = get_tree().get_root().get_node("World/Recruit")

func _ready():
	visible = false

func print_sign(text):
	face_container.free()
	tb.align = Label.ALIGN_CENTER
	tb.valign = Label.ALIGN_CENTER
	tb.text = text
	visible = true

func start_printing(dialog_json, npc_convo):
	audio.stream = text_sound
	tb.text = ""
	visible = true
	in_dialog = true
	
	dialog = load_dialog(dialog_json)
	conversation = npc_convo
	text = dialog[conversation].json_escape()
	
	dialog_loop()

func dialog_loop():
	if not busy:
		while step < text.length():
			print_dialog(text)
			step +=1
			if $PrintTimer.is_stopped():
				$PrintTimer.start(print_delay)
			yield($PrintTimer, "timeout")
			if active == false:
				ending_line = tb.get_line_count()
				break
			if busy:
				break

func flash_cursor():
	yield(get_tree().create_timer(0.3), "timeout")
	print("flashing cursor")
	var added_text = tb.text.insert(tb.text.length() - 1, "§")
	var deleted_text = tb.text
	
	while active == false:
		tb.text = added_text
		yield(get_tree().create_timer(0.3), "timeout")
		if active:
			break
		tb.text = deleted_text
		yield(get_tree().create_timer(0.3), "timeout")

func remove_cursor():
	var cursor_position = tb.text.rfind("§")
	if cursor_position != -1:
		var removed_cursor = tb.text
		removed_cursor.erase(cursor_position, 1)
		tb.text = removed_cursor

func _input(event):
	if event.is_action("inspect"):
		if in_dialog:
			print(text.length())
			if step >= text.length():
				print("reached end")
				stop_printing()
			
			if active == false:
				active = true
				remove_cursor()
				if tb.get_line_count() >= 3:
					tb.text = ""
				dialog_loop()
				starting_line = tb.get_line_count()


func load_dialog(dialog_json) -> Dictionary: #loads json and converts it into a dictionary
	var file = File.new()

	file.open(dialog_json, file.READ)
	var text = file.get_as_text()
	var dialog = JSON.parse(text).result
	return dialog


func print_dialog(string):
	if tb.get_line_count() == 4:
		tb.lines_skipped = 1
	else:
		tb.lines_skipped = 0
	
	var character = string.substr(step, 1)
	
	if character == ",": #or character == "." or character == "?" or character == "!":
		print("pausing for punctuation")
		$PrintTimer.stop()
		$PrintTimer.start($PrintTimer.time_left + punctuation_delay)
		print("insterted char: ", character)
		tb.text = tb.text.insert(step, character)
	
	elif character == "\\":
		print("skipping escape char")
		step += 1
		character = string.substr(step, 1)
		if character == "n":
			active = false
			flash_cursor()
			print("adding back newline")
			tb.text = tb.text.insert(step, "\n")
			
	
	elif character == "/":
		var command = string.substr(step, -1)
		var first_space = command.find(" ")
		if first_space == -1:
			pass
		else:
			command = command.left(first_space)
		
		print("doing command: ", command)
		parse_command(command)
		step += command.length()
	else:
		print("insterted char: ", character)
		tb.text = tb.text.insert(step, character)
		#audio.stop()
		audio.play()


func stop_printing():
	print("ended dialog")
	#branch = "" #may be undesired to reset the convo
	#already_talked = true
	
	step = 0
	#visible = false
	in_dialog = false
	active = true
	busy = false
	player.disabled = false
	player.invincible = false

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
	if string == "":
		printerr("COMMAND ERROR: no npc given for /name")
		return
	var display_name = string.capitalize() + ": "
	tb.text = tb.text.insert(0, display_name)
	
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
	
	if id == null or distance == null:
		printerr("COMMAND ERROR: not enough arguements for /walk")
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
