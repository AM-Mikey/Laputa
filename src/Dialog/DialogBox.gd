extends Control

signal dialog_finished

@export var print_delay = 0.05
@export var do_delay = true
@export var punctuation_delay = 0.3

var busy = false #executing commands, ignore input
var auto_input = false
var active = false #actively printing
var current_dialog_json
var current_text_array
var step: int = 0 #step in printing dialog

var flash_original_text = ""
enum {FLASH_NONE, FLASH_NORMAL, FLASH_END}
var flash_type = FLASH_NONE
var flash_step: int = 0

@onready var tb = $Margin/HBox/RichTextBox
@onready var face_container = $Margin/HBox/Face
@onready var face_sprite = $Margin/HBox/Face/Sprite2D
@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	tb.text = "\n" #""
	
	for e in get_tree().get_nodes_in_group("Enemies"):
		e.disable()



#func print_sign():
	#face_container.free()
	##tb.bbcode_text = "\n" + "[b][center]" + text
	#print(text)
	##pc.disable()
	#pc.mm.cached_state = pc.mm.current_state
	#pc.mm.change_state("inspect")
	#dialog_loop()
#
#
#func print_flavor_text(justification := "no_face"):
	#print(text)
	#justify_text(justification)
	#align_box()
	##pc.disable()
	#pc.mm.cached_state = pc.mm.current_state
	#pc.mm.change_state("inspect")
	#dialog_loop()


func start_printing(dialog_json, conversation: String):
	current_dialog_json = dialog_json
	active = true
	
	var dialog = load_dialog_json(dialog_json)
	conversation = conversation.to_lower()
	
	if not dialog.has(conversation): #null convo
		printerr("No conversation with the name: ", conversation)
	else:
		current_text_array = split_text(dialog[conversation]) #contains array of: command, newline as blank string, text string
	align_box()
	#pc.disable()
	pc.mm.cached_state = pc.mm.current_state
	pc.mm.change_state("inspect")
	run_text_array(current_text_array)


func load_dialog_json(dialog_json) -> Dictionary: #loads json and converts it into a dictionary
	var file = FileAccess.open(dialog_json, FileAccess.READ)
	var loaded_text = file.get_as_text()
	var json = JSON.new()
	json.parse(loaded_text)
	var out = json.get_data()
	return out



func split_text(text) -> Array: #TODO: regex removes all spaces between commands, not just the first (i'm talking /face  about you) 
	var out = []
	text = text.strip_edges().replace("\t", "") #remove first and last newlines, remove tabulation
	var regex = RegEx.new()
	regex.compile(r'(*NOTEMPTY)(?=\/)(\S*)(?=\n|$| )|(?! )(.*?)(?= \/|\n|$)|(\n)') #took me so long to come up with, if a command doesnt register properly, check this in https://regex101.com/
	for result in regex.search_all(text):
		out.push_back(result.get_string())
	return out


func run_text_array(text_array):
	if step == current_text_array.size():
		#print("reached end")
		active = false
		flash_type = FLASH_END
		flash_original_text = tb.text
		$FlashTimer.start(0.1)
		return
	var string = text_array[step]

	if string.begins_with("/"):
		#print("did command: ", string)
		await $CommandHandler.parse_command(string.lstrip("/"))
		step += 1
		run_text_array(text_array)
	elif string == "\n":
		step += 1
		if auto_input:
			tb.text += "\n"
			run_text_array(text_array)
			return
		active = false
		flash_type = FLASH_NORMAL
		flash_original_text = tb.text
		$FlashTimer.start(0.3)
	else:
		print(string)
		await run_text_string(string)
		step += 1
		run_text_array(text_array)


func run_text_string(string):
	for character in string:
		tb.text += character
		am.play("npc_dialog")
		if do_delay:
			if character == ",": #or character == "." or character == "?" or character == "!": ##leave out other punctuation since the pause after a line is bad UX
				await get_tree().create_timer(punctuation_delay).timeout
			else:
				await get_tree().create_timer(print_delay).timeout


func _on_flash_timer_timeout():
	if busy: return
	if flash_type == FLASH_NORMAL:				#TODO: delete previous text after third line
		if tb.text == flash_original_text:
			tb.text += " §"#"[color=#ffffff40] [/color]"
		else:
			tb.text = flash_original_text
	elif flash_type == FLASH_END:
		match flash_step:
			0:
				tb.text = flash_original_text + "[color=goldenrod] |[/color]"
				$FlashTimer.wait_time = 0.1
			1:
				tb.text = flash_original_text + "[color=goldenrod] \\[/color]"
				$FlashTimer.wait_time = 0.075
			2:
				tb.text = flash_original_text + "[color=goldenrod] -[/color]"
				$FlashTimer.wait_time = 0.1
			3:
				tb.text = flash_original_text + "[color=goldenrod] /[/color]"
				$FlashTimer.wait_time = 0.2
		flash_step = (flash_step + 1) % 4 #warning, this is never reset


func _input(event):
	if event.is_action_pressed("ui_accept")and not busy:
		if not active:
			if step == current_text_array.size():
				exit()
				return
			if auto_input:
				return
			do_delay = true
			active = true
			$FlashTimer.stop()
			tb.text = flash_original_text + "\n" #remove cursor, add back newline
			run_text_array(current_text_array)
		
		elif not auto_input: #active
			do_delay = false


func exit():
	emit_signal("dialog_finished")
	if is_instance_valid(pc):
		pc.mm.change_state("run") #change to run so we don't continue a jump
	for e in get_tree().get_nodes_in_group("Enemies"):
		e.enable()
	queue_free()

### HELPERS


#func justify_text(justification: String): #depreciated
	#match justification:
		#"face":
			#$Margin/HBox/NoFaceSpacer.visible = false
			#$Margin/HBox/Face.visible = true
		#"no_face":
			#$Margin/HBox/NoFaceSpacer.visible = true
			#$Margin/HBox/Face.visible = false

func align_box():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	var pc_pos = pc.global_position
	var camera = get_viewport().get_camera_2d()
	var camera_center = camera.get_screen_center_position()

	if pc_pos.y < camera_center.y + (viewport_size.y / 6): #bottom
		position.y = viewport_size.y - (size.y + 16)
	else: #top
		position.y = 16


func flip_face(dir = "auto"):
	if dir == "auto":
		match face_container.get_index():
			0: dir = "right"
			1: dir = "left"

	match dir:
		"left":
			face_container.get_parent().move_child(face_container, 0)
			#face_sprite.scale.x = 1
			face_sprite.flip_h = false
		"right":
			face_container.get_parent().move_child(face_container, 1)
			#face_sprite.scale.x = -1
			face_sprite.flip_h = true

### SIGNALS

func on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	#rect_size = get_tree().get_root().size / world.resolution_scale
	size.x = min(viewport_size.x, 400)
	position.x = (viewport_size.x - size.x) /2
	position.y = viewport_size.y - 80
