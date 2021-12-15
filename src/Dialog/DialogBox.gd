extends Control

signal dialog_finished

var text_sound = load("res://assets/SFX/Placeholder/snd_msg.ogg")

var prompt_sound = load("res://assets/SFX/Placeholder/snd_menu_prompt.ogg")
var move_sound = load("res://assets/SFX/Placeholder/snd_menu_move.ogg")
var select_sound = load("res://assets/SFX/Placeholder/snd_menu_select.ogg")



var dialog
var conversation: String
var text

export var print_delay = 0.05
export var do_delay = true
export var punctuation_delay = 0.3
var in_dialog = false
var active = true
var busy = false
var auto_input = false

var current_dialog_json
var step: int = 0 #step in printing dialog

onready var tb = $Margin/HBox/RichTextBox
onready var face_container = $Margin/HBox/Face
onready var face_sprite = $Margin/HBox/Face/Sprite
onready var audio = $AudioStreamPlayer


onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")

func _ready():
	var _con = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()
	audio.stream = text_sound
	tb.bbcode_text = "\n" #""
	
	#get_parent().add_child(load("res://src/Dialog/TopicBox.tscn").instance()) #TESTING

func print_sign():
	face_container.free()
	tb.bbcode_text = "\n" + "[b][center]" + text
	pc.is_inspecting = true


func print_flavor_text():
	#custom_constants/margin_right = 64
	#custom_constants/margin_left = 64
	#face_container.free()
	in_dialog = true
	pc.is_inspecting = true
	text = text
	print(text)
	dialog_loop()

func start_printing(dialog_json, conversation_to_print):
	current_dialog_json = dialog_json
	in_dialog = true
	
	dialog = load_dialog(dialog_json)
	text = dialog[conversation_to_print].strip_edges().replace("\t", "") #strip edges to clean up first and last newlines ## remove tabulation
	print(text)
	
	pc.disabled = true
	pc.invincible = true
	pc.is_inspecting = true
	dialog_loop()


func load_dialog(dialog_json) -> Dictionary: #loads json and converts it into a dictionary
	var file = File.new()
	file.open(dialog_json, file.READ)
	
	var loaded_text = file.get_as_text()
	var loaded_dialog = JSON.parse(loaded_text).result
	return loaded_dialog


func dialog_loop():
	if not busy:
		while step < text.length(): #not completed: 
			print_dialog(text)
			step +=1
			if do_delay:
				if $PrintTimer.is_stopped():
					$PrintTimer.start(print_delay)
				yield($PrintTimer, "timeout")
			
			if busy or not active:
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
	if event.is_action_pressed("ui_accept") and in_dialog and not auto_input:
		if step >= text.length():
			print("reached end")
			stop_printing()
		
		if not active:
			do_delay = true
			active = true
			remove_cursor()
			
			print("adding back newline")
			tb.bbcode_text += "\n"
			
#				if tb.get_line_count() > 3: #was greater than or equal to, made starting on line 3 impossible
#					tb.bbcode_text = ""
			dialog_loop()
		
		else: #active
			do_delay = false



func print_dialog(string):
#	if tb.get_line_count() == 4: #failsafe for if we overflow
#		tb.remove_line(1)

	
	var character = string.substr(step, 1)
	
	if character == ",": #or character == "." or character == "?" or character == "!": ##leave out other punctuation since the pause after a line is bad UX
		print("pausing for punctuation")
		$PrintTimer.stop()
		$PrintTimer.start($PrintTimer.time_left + punctuation_delay)
		print("insterted char: ", character)
		tb.bbcode_text += character
	
	
	elif character == "\n" and not auto_input:
			print("skipping newline")
			active = false
			flash_cursor()
	
	
	elif character == "/":
		var command = string.substr(step, -1)
		var first_space = command.find(" ")
		var first_newline = command.find("\n")
		
		if first_space < first_newline: #the space came first
			command = command.left(first_space)
			step += command.length()
		elif first_space > first_newline: #the newline came first
			command = command.left(first_newline)
			step += command.length() #-1 #believe it or not breaking the step count breaks the dialog (huh who knew?)
		
		print("doing command: ", command)
		$CommandHandler.parse_command(command)
		
		
		
	else:
		print("step " + str(step) + " : " + character)
		tb.bbcode_text += character
		audio.play()


func stop_printing():
	print("ended dialog")
	emit_signal("dialog_finished")
	if is_instance_valid(pc):
		pc.get_node("PlayerCamera").position = Vector2.ZERO
		pc.disabled = false
		pc.invincible = false
		pc.is_inspecting = false
	queue_free()




func _physics_process(_delta):
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	
	var active_camera = get_current_camera()
	
	if active_camera.offset_v >= 1 / world.resolution_scale: #more than halfway down
		rect_position.y = viewport_size.y - (rect_size.y + 16) #bottom
	if active_camera.offset_v <= -1 / world.resolution_scale: #more than halfway up
		rect_position.y = 16 #top
	
func on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	#rect_size = get_tree().get_root().size / world.resolution_scale
	rect_size.x = min(viewport_size.x, 400)
	rect_position.x = (viewport_size.x - rect_size.x) /2
	rect_position.y = viewport_size.y - 80

func get_current_camera() -> Node:
	var cameras = get_tree().get_nodes_in_group("Cameras")
	for c in cameras:
		if c.current:
			print("found current camera")
			return c
	printerr("ERROR: could not find current camera!")
	return cameras[0]
