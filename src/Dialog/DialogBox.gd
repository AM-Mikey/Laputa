extends Control

signal dialog_finished

@export var print_delay = 0.05
@export var do_delay = true
@export var punctuation_delay = 0.3

var busy = false #executing commands, ignore input
var awaiting_merge = false
var auto_input = false
var active = false #actively printing
var current_dialog_json
var current_text_array
var step: int = 0 #step in printing dialog
var is_sign = false
var is_flavor = false

var flash_original_text = ""
enum {FLASH_NONE, FLASH_NORMAL, FLASH_END}
var flash_type = FLASH_NONE
var flash_step: int = 0
var dl: Node


@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")


func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	
	for e in get_tree().get_nodes_in_group("Enemies"):
		e.disable()
	
	$NPC.visible = false
	$Flat.visible = false
	$Response.visible = false
	$Name.visible = false
	$Face.visible = false
	$Options.visible = false


func start_printing(dialog_json, conversation: String):
	$NPC.visible = true
	dl = $NPC/DialogNPC
	dl.text = ""
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


func start_printing_sign(text: String):
	$Flat.visible = true
	dl = $Flat/DialogFlat
	dl.text = ""
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active = true
	do_delay = false
	auto_input = true
	is_sign = true
	current_text_array = split_text(text) #contains array of: command, newline as blank string, text string
	align_box()
	pc.mm.cached_state = pc.mm.current_state
	pc.mm.change_state("inspect")
	run_text_array(current_text_array)


func start_printing_flavor_text(text: String):
	$Flat.visible = true
	dl = $Flat/DialogFlat
	dl.text = ""
	active = true
	is_flavor = true
	current_text_array = split_text(text) #contains array of: command, newline as blank string, text string
	align_box()
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
	if !is_sign:
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
		if !is_sign:
			flash_type = FLASH_END
			flash_original_text = dl.text
			$FlashTimer.start(0.1)
		return
	var string = text_array[step]
	if string.begins_with("/"):
		#print("did command: ", string)
		await $CommandHandler.parse_command(string.lstrip("/"))
		step += 1
		print("step: ", step)
		run_text_array(text_array)
	elif string == "\n":
		step += 1
		print("step: ", step)
		if auto_input:
			dl.text += "\n"
			run_text_array(text_array)
			return
		active = false #otherwise it sets active == false and ends the loop
		if !is_sign:
			flash_type = FLASH_NORMAL
			flash_original_text = dl.text
			$FlashTimer.start(0.3)
	else:
		print(string)
		await run_text_string(string)
		step += 1
		print("step: ", step)
		run_text_array(text_array)


func run_text_string(string):
	for character in string:
		dl.text += character
		if do_delay:
			am.play("npc_dialog")
			if character == ",": #or character == "." or character == "?" or character == "!": ##leave out other punctuation since the pause after a line is bad UX
				await get_tree().create_timer(punctuation_delay).timeout
			else:
				await get_tree().create_timer(print_delay).timeout


func _on_flash_timer_timeout():
	if busy: return
	if flash_type == FLASH_NORMAL:				#TODO: delete previous text after third line
		if dl.text == flash_original_text:
			dl.text += " §"#"[color=#ffffff40] [/color]"
		else:
			dl.text = flash_original_text
	elif flash_type == FLASH_END:
		match flash_step:
			0:
				dl.text = flash_original_text + "[color=goldenrod] ¤[/color]"
				$FlashTimer.wait_time = 0.1
			1:
				dl.text = flash_original_text + "[color=goldenrod] €[/color]"
				$FlashTimer.wait_time = 0.075
			2:
				dl.text = flash_original_text + "[color=goldenrod] £[/color]"
				$FlashTimer.wait_time = 0.1
			3:
				dl.text = flash_original_text + "[color=goldenrod] ¢[/color]"
				$FlashTimer.wait_time = 0.2
		flash_step = (flash_step + 1) % 4 #warning, this is never reset


func _input(event):
	if event.is_action_pressed("ui_accept") and not busy: #bypass can_input
		if $Options.is_displaying: return #so it doesn't input
		if awaiting_merge:
			awaiting_merge = false
			$CommandHandler.seek("/m", true)
		elif auto_input:
			return
		elif active: #if already active, speed text up
			do_delay = false 
		else:
			progress_text()


func progress_text(with_newline = true):
	if step == current_text_array.size():
		exit()
		return
	do_delay = true
	active = true
	$FlashTimer.stop()
	if with_newline:
		dl.text = flash_original_text + "\n" #remove cursor, add back newline
	else:
		dl.text = flash_original_text
	run_text_array(current_text_array)



func exit():
	emit_signal("dialog_finished")
	if is_instance_valid(pc):
		pc.mm.change_state("run") #change to run so we don't continue a jump
	for e in get_tree().get_nodes_in_group("Enemies"):
		e.enable()
	await align_out()
	if w.ui.has_node("HUD"):
			w.ui.get_node("HUD").visible = true
	queue_free()



### HELPERS

func align_box():
	var viewport_size = get_tree().get_root().size / w.resolution_scale
	var pc_pos = pc.global_position
	var camera = get_viewport().get_camera_2d()
	var camera_center = camera.get_screen_center_position()


	var tween = create_tween()
	var tween2 = create_tween()
	if pc_pos.y < camera_center.y + (viewport_size.y / 6): #bottom
		position.y = viewport_size.y
		tween.tween_property(self, "position", Vector2(position.x, viewport_size.y - (size.y + 16)), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		modulate = Color.TRANSPARENT
		tween2.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	else: #top
		position.y = 0 - size.y
		tween.tween_property(self, "position", Vector2(position.x, 16), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		modulate = Color.TRANSPARENT
		tween2.tween_property(self, "modulate", Color.WHITE, 0.1)
		if w.ui.has_node("HUD"):
			w.ui.get_node("HUD").visible = false

func align_out():
	var viewport_size = get_tree().get_root().size / w.resolution_scale
	var pc_pos = pc.global_position
	var camera = get_viewport().get_camera_2d()
	var camera_center = camera.get_screen_center_position()

	var tween = create_tween()
	var tween2 = create_tween()
	if pc_pos.y < camera_center.y + (viewport_size.y / 6): #bottom
		position.y = viewport_size.y - (size.y + 16)
		tween.tween_property(self, "position", Vector2(position.x, viewport_size.y), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		modulate = Color.WHITE
		tween2.tween_property(self, "modulate", Color.TRANSPARENT, 0.1)
		await tween.finished
	
	else: #top
		position.y = 16
		tween.tween_property(self, "position", Vector2(position.x, 0 - size.y), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		modulate = Color.WHITE
		tween2.tween_property(self, "modulate", Color.TRANSPARENT, 0.1)
		await tween.finished


func display_name(name: String):
	$Name.visible = false
	$Name/Shadow.global_position = $Name/HBox/Label.global_position - Vector2.ONE
	$Name/HBox/Label.text = name.capitalize()
	$Name/Shadow.text = name.capitalize()
	await get_tree().create_timer(0.01).timeout
	$Name/Shadow.size = $Name/HBox/Label.size
	$Name/Panel.size.x = $Name/HBox/Label.size.x + 19

func hide_name():
	$Name.visible = false


func flip_face(dir = "auto"):
	if dir == "auto":
		match $Face.get_index():
			0: dir = "right"
			1: dir = "left"
	match dir:
		"left":
			$Face.get_parent().move_child($Face, 0)
			$Face/Sprite2D.flip_h = false
		"right":
			$Face.get_parent().move_child($Face, 1)
			$Face/Sprite2D.flip_h = true



### SIGNALS

func on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / w.resolution_scale
	#rect_size = get_tree().get_root().size / w.resolution_scale
	size.x = min(viewport_size.x, 400)
	position.x = (viewport_size.x - size.x) /2
	position.y = viewport_size.y - 80
