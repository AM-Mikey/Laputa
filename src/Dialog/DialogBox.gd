extends Control

signal dialog_finished

var text

@export var print_delay = 0.05
@export var do_delay = true
@export var punctuation_delay = 0.3
var in_dialog = false
var active = true
var busy = false
var auto_input = false

var current_dialog_json
var step: int = 0 #step in printing dialog

@onready var tb = $Margin/HBox/RichTextBox
@onready var face_container = $Margin/HBox/Face
@onready var face_sprite = $Margin/HBox/Face/Sprite2D

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	tb.text = "\n" #""

func print_sign():
	face_container.free()
	in_dialog = true
	#tb.bbcode_text = "\n" + "[b][center]" + text
	print(text)
	#pc.disable()
	pc.mm.cached_state = pc.mm.current_state
	pc.mm.change_state("inspect")
	dialog_loop()


func print_flavor_text(justification := "no_face"):
	in_dialog = true
	print(text)
	justify_text(justification)
	align_box()
	#pc.disable()
	pc.mm.cached_state = pc.mm.current_state
	pc.mm.change_state("inspect")
	dialog_loop()


func start_printing(dialog_json, conversation: String, justification := "no_face"):
	current_dialog_json = dialog_json
	in_dialog = true
	
	var dialog = load_dialog(dialog_json)
	conversation = conversation.to_lower()
	if not dialog.has(conversation): #null convo
		text = "hey dummy, there's no conversation with the name: " + conversation
	else:
		text = dialog[conversation].strip_edges().replace("\t", "") #strip edges to clean up first and last newlines ## remove tabulation
	
	#print(text)
	justify_text(justification)
	align_box()
	#pc.disable()
	pc.mm.cached_state = pc.mm.current_state
	pc.mm.change_state("inspect")
	dialog_loop()


func load_dialog(dialog_json) -> Dictionary: #loads json and converts it into a dictionary
	var file = FileAccess.open(dialog_json, FileAccess.READ)
	
	var loaded_text = file.get_as_text()
	var test_json_conv = JSON.new()
	test_json_conv.parse(loaded_text)
	var loaded_dialog = test_json_conv.get_data()
	return loaded_dialog


func dialog_loop():
	if not busy:
		while step < text.length(): #not completed: 
			print_dialog(text)
			step +=1
			if do_delay:
				if $PrintTimer.is_stopped():
					$PrintTimer.start(print_delay)
				await $PrintTimer.timeout
			
			if busy or not active:
				break

func flash_cursor():
	await get_tree().create_timer(0.3).timeout
	var added_text = tb.text + "§"
	var deleted_text = tb.text
	
	while not active:
		tb.text = added_text
		await get_tree().create_timer(0.3).timeout
		if active:
			break
		tb.text = deleted_text
		await get_tree().create_timer(0.3).timeout

func remove_cursor():
	var cursor_position = tb.text.rfind("§")
	if cursor_position != -1:
		var removed_cursor = tb.text
		removed_cursor.erase(cursor_position, 1)
		tb.text = removed_cursor

func _input(event):
	if event.is_action_pressed("ui_accept") and in_dialog and not auto_input:
		if step >= text.length():
			print("reached end")
			exit()
		
		if not active:
			do_delay = true
			active = true
			remove_cursor()
			
			print("adding back newline")
			tb.text += "\n"
			
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
		tb.text += character
	
	
	elif character == "\n" and not auto_input:
			print("skipping newline")
			active = false
			flash_cursor()
	
	
	elif character == "/":
		var command = string.substr(step+1, -1) #everything after the slash
		var first_space = 999
		var first_newline = 999
		var first_slash = 999
		
		if " " in command:
			first_space = command.find(" ")
		if "\n" in command:
			first_newline = command.find("\n")
		if "/" in command:
			first_slash = command.find("/")


		var first = min(min(first_space, first_newline), first_slash) #first command end character
		command = command.left(first)
		step += command.length()
		if first == first_space: #skip space
			step += 1
		
		print("doing command: ", command)
		$CommandHandler.parse_command(command)
		
		
		
	else:
		print("step " + str(step) + " : " + character)
		tb.text += character
		am.play("npc_dialog")


func exit():
	print("ended dialog")
	emit_signal("dialog_finished")
	if is_instance_valid(pc):
		pc.get_node("PlayerCamera").position = Vector2.ZERO
		#pc.enable()
		await get_tree().process_frame
		pc.mm.change_state("run") #change to run so we don't continue a jump
	queue_free()

### HELPERS


func justify_text(justification: String):
	match justification:
		"face":
			$Margin/HBox/NoFaceSpacer.visible = false
			$Margin/HBox/Face.visible = true
		"no_face":
			$Margin/HBox/NoFaceSpacer.visible = true
			$Margin/HBox/Face.visible = false

func align_box():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	var pc_pos = pc.global_position
	var camera
	for c in get_tree().get_nodes_in_group("Cameras"):
		if c.current:
			camera = c
	var camera_center = camera.get_screen_center_position()

	if pc_pos.y < camera_center.y + (viewport_size.y / 6): #bottom
		position.y = viewport_size.y - (size.y + 16)
	else: #top
		position.y = 16


func flip_face(dir = "auto"):
	if dir == "auto":
		var face_index = face_container.get_index()
		match face_index:
			0: dir = "right"
			1: dir = "left"

	match dir:
		"left":
			face_container.get_parent().move_child(face_container, 0)
			face_sprite.scale.x = 1
		"right":
			face_container.get_parent().move_child(face_container, 1)
			face_sprite.scale.x = -1

### SIGNALS

func on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	#rect_size = get_tree().get_root().size / world.resolution_scale
	size.x = min(viewport_size.x, 400)
	position.x = (viewport_size.x - size.x) /2
	position.y = viewport_size.y - 80
