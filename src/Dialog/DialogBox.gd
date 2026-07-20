extends Control

signal dialog_finished

@export var print_delay = 0.03
@export var do_delay = true
@export var punctuation_delay = 0.3

var busy = false #executing commands, ignore input
var awaiting_merge = false
var do_force_end = false
var auto_input = false
var active = false #actively printing
var current_dialog_json
var current_text_array
var text_stripped_of_commands
var step := 0 #step in printing dialog
var character_shown_count := 0
var character_is_newline_count := 0
var character_is_bbcode_count := 0
#var carat_visible_character_size := 2
var is_sign = false
var is_flavor = false
var is_exiting = false

var flash_original_text = ""
enum {FLASH_NONE, FLASH_NORMAL, FLASH_END}
var flash_type = FLASH_NONE
var flash_step: int = 0
var dl: Node


@onready var w = get_tree().get_root().get_node("World")
@onready var pc = f.pc()


func _ready():
	for e in get_tree().get_nodes_in_group("Enemies"):
		e.disable()

	$NPC.visible = false
	$Flat.visible = false
	$Response.visible = false
	$Name.visible = false
	$Face.visible = false
	$Options.visible = false

	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed()

func start_printing(dialog_json, conversation: String, next_state = "inspect"): #TODO: use shown characters for sign and other stuff too
	current_dialog_json = dialog_json
	active = true
	var dialog = _load_dialog_json(dialog_json)
	conversation = conversation.to_lower()

	if !dialog.has(conversation): #null convo
		printerr("ERROR: No conversation in file: ", dialog_json, " with name: ", conversation)
		exit()
		return
	else:
		current_text_array = split_text(dialog[conversation]) #contains array of: command, newline as blank string, text string
		text_stripped_of_commands = get_text_stripped_of_commands(0)

	if get_text_array_starts_with_face():
		$NPC.visible = true
		dl = $NPC/DialogNPC
	else:
		$Flat.visible = true
		dl = $Flat/DialogFlat
	dl.text = ""

	align_box()
	pc.mm.cached_state = pc.mm.current_state
	pc.mm.change_state(next_state)
	dl.text = text_stripped_of_commands
	dl.visible_characters = 0
	run_text_array(current_text_array)


func start_printing_sign(text: String):
	$Flat.visible = true
	size = Vector2(384, 78)
	_resolution_scale_changed() #to update after size
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
	size = Vector2(384, 78)
	_resolution_scale_changed() #to update after size
	dl = $Flat/DialogFlat
	dl.text = ""
	active = true
	is_flavor = true
	current_text_array = split_text(text) #contains array of: command, newline as blank string, text string
	align_box()
	pc.mm.cached_state = pc.mm.current_state
	pc.mm.change_state("inspect")
	run_text_array(current_text_array)


func _load_dialog_json(dialog_json) -> Dictionary: #loads json and converts it into a dictionary
	var file = FileAccess.open(dialog_json, FileAccess.READ)
	var loaded_text = file.get_as_text()
	var json = JSON.new()
	json.parse(loaded_text)
	var out = json.get_data()
	return out


func split_text(text) -> Array:
	var out = []
	if !is_sign:
		text = text.strip_edges().replace("\t", "") #remove first and last newlines, remove tabulation
	var regex = RegEx.new()
	regex.compile(r'(*NOTEMPTY)(?=\/)(\S*)(?=\r?\n|$| )|(?! )([^\r\n]+?)(?= \/|\r?\n|$)|(\r?\n)')
	for result in regex.search_all(text):
		out.append(result.get_string())
	return restore_command_spacing(out)

func restore_command_spacing(tokens: Array) -> Array:
	#reinsert exactly one space wherever a run of commands separates two text tokens on the same line.
	var out = []
	var pending_command := false
	var has_prior_text_this_line := false
	for token in tokens:
		if token.begins_with("/"):
			pending_command = true
			out.append(token)
			continue
		var is_newline = token == "\n" or token == "\r\n" or token == ""
		if pending_command and has_prior_text_this_line and !is_newline:
			out.append(" ")
		out.append(token)
		pending_command = false
		has_prior_text_this_line = !is_newline
	return out


func get_text_stripped_of_commands(from_step: int) -> String:
	var out = ""
	var array_of_desirable_text = PackedStringArray([])
	var step_index := 0
	for i in current_text_array:
		if step_index < from_step:
			pass
		elif !i.contains("/"):
			array_of_desirable_text.append(i)
		step_index += 1
	out = out.join(array_of_desirable_text)
	#print(out)
	return out


func run_text_array(text_array, from_input := false): #step is always the next step ready to do, not the one just done
	if step == current_text_array.size() || do_force_end:
		#print("reached end")
		active = false
		if !is_sign:
			flash_type = FLASH_END
			flash_original_text = dl.text
			$FlashTimer.start(0.1)
		return
	var string = text_array[step]

	if string.begins_with("/"):
		var command_is_first = true if step == 0 else false
		await $CommandHandler.parse_command(string.lstrip("/"), command_is_first)
		step += 1
		print("step: ", step)
		run_text_array(text_array)

	elif string == "\n" or string == "\r\n" or string == "":
		if auto_input or from_input:
			step += 1
			character_shown_count += 1
			character_is_newline_count += 1
			print("step: ", step)
			run_text_array(text_array)
		else:
			active = false #otherwise it sets active == false and ends the loop
			if !is_sign:
				flash_type = FLASH_NORMAL
				flash_original_text = dl.text
				$FlashTimer.start(0.3)

				dl.text = flash_original_text.insert(get_raw_index(), "  ") #needs to add cinc because windows probably treats it as two characters
				dl.visible_characters += 2
				#if dl.get_character_line(current_character_index) < current_character_index + character_is_newline_count + 3: #when the carat is on a new line
					#carat_visible_character_size = 3
				#else:
					#carat_visible_character_size = 2
				#dl.visible_characters += carat_visible_character_size
				print("starting carat")

	else:
		#print(string)
		await run_text_string(string)
		step += 1
		print("step: ", step)
		run_text_array(text_array)


func run_text_string(string):
	var current_character_string_index = 0
	for character in string:
		var is_last_character = current_character_string_index == string.length() - 1
		dl.visible_characters = character_shown_count + 1
		character_shown_count += 1
		if do_delay:
			am.play("npc_dialog")
			if is_last_character:
				return
			elif character in [",", ".", "?", "!", ":", ";"]:
				await get_tree().create_timer(punctuation_delay, true, false).timeout
			else:
				await get_tree().create_timer(print_delay, true, false).timeout
		else: #no delay
			if is_last_character:
				return
		current_character_string_index += 1

func _on_flash_timer_timeout():
	if busy: return
	if flash_type == FLASH_NORMAL:
		match flash_step:
			0:
				dl.text = flash_original_text.insert(get_raw_index(), " §") #needs to add cinc because windows probably treats it as two characters
			1:
				dl.text = flash_original_text.insert(get_raw_index(), "  ") #needs to add cinc because windows probably treats it as two characters
		flash_step = (flash_step + 1) % 2

	elif flash_type == FLASH_END:
		dl.visible_characters += 2
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
		flash_step = (flash_step + 1) % 4


func _input(event):
	if event.is_action_pressed("ui_accept") and not busy: #bypass inp.can_act
		if $Options.is_displaying: return #so it doesn't input
		if awaiting_merge:
			awaiting_merge = false
			$CommandHandler.seek("/m", true)
		elif active: #if already active, speed text up
			do_delay = false
		else:
			var current_line = dl.get_character_line(character_shown_count - 1)
			print("line is number: ", current_line)
			if current_line % 3 == 2: #&& current_line != 0:
				dl.scroll_to_line(current_line + 1)
			progress_text()


func progress_text():
	if step == current_text_array.size() || do_force_end:
		setup_next_conversation()
		return
	do_delay = true
	active = true
	$FlashTimer.stop()
	flash_step = 0
	dl.visible_characters -= 2
	dl.text = flash_original_text
	run_text_array(current_text_array, true)

func setup_next_conversation():
	var npc: Node
	for n in get_tree().get_nodes_in_group("NPCs"):
		if n.dialog_box == self:
			npc = n
	if npc:
		# Find first uncompleted index in each queue, or last index as fallback
		var main_next = get_next_conversation_index(npc.conversation_queue) if npc.conversation_queue.size() > 0 else -1
		var side_next = get_next_conversation_index(npc.side_conversation_queue) if npc.side_conversation_queue.size() > 0 else -1

		var main_exhausted = npc.conversation_queue.size() == 0 || (main_next == npc.conversation_queue.size() - 1 && npc.conversation_queue[main_next][4])
		var side_exhausted = npc.side_conversation_queue.size() == 0 || (side_next == npc.side_conversation_queue.size() - 1 && npc.side_conversation_queue[side_next][4])

		#print("logic_time")
		if !main_exhausted:
			npc.next_conversation_queue_name = "conversation_queue"
			npc.next_conversation_index = main_next
			print("progressing to next main convo")
		elif !side_exhausted:
			npc.next_conversation_queue_name = "side_conversation_queue"
			npc.next_conversation_index = side_next
			print("progressing to next side convo")
		else:
			# All conversations completed, check if final entries are repeatable
			var main_repeatable = npc.conversation_queue.size() > 0 && npc.conversation_queue[main_next][3]
			var side_repeatable = npc.side_conversation_queue.size() > 0 && npc.side_conversation_queue[side_next][3]

			if side_repeatable:
				npc.next_conversation_queue_name = "side_conversation_queue"
				npc.next_conversation_index = side_next
				print("repeating last side convo")
			elif main_repeatable:
				npc.next_conversation_queue_name = "conversation_queue"
				npc.next_conversation_index = main_next
				print("repeating last main convo")
			else:
				exit()
				return

		var stored_next_convo = npc.get(npc.next_conversation_queue_name)[npc.next_conversation_index]
		if stored_next_convo && stored_next_convo[2] && !stored_next_convo[4]: # forced and not yet completed
			print("forcing next convo")
			$FlashTimer.stop()
			flash_step = 0
			dl.text = ""
			dl.visible_characters = 0
			step = 0
			npc.get(npc.next_conversation_queue_name)[npc.next_conversation_index][4] = true #completed
			SaveSystem.write_dialog_data_to_temp(w.current_level, npc)
			start_printing(npc.dialog_json, stored_next_convo[0])
		else:
			exit()
	else:
		exit()

func get_next_conversation_index(queue: Array) -> int:
	for i in queue.size():
		if !queue[i][4]:
			return i
	return queue.size() - 1 # all completed, return last as fallback

func exit():
	if is_exiting: return
	is_exiting = true
	emit_signal("dialog_finished")
	if is_instance_valid(pc):
		pc.mm.change_state("run") #change to run so we don't continue a jump
	for e in get_tree().get_nodes_in_group("Enemies"):
		e.enable()
	await align_out()
	if f.hud():
		f.hud().visible = true
	queue_free()



### HELPERS

func align_box():
	var viewport_size = get_tree().get_root().size / vs.resolution_scale
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
		if f.hud():
			f.hud().visible = false

func align_out():
	var viewport_size = get_tree().get_root().size / vs.resolution_scale
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


func display_name(d_name: String):
	$Name/Shadow.global_position = $Name/HBox/Label.global_position - Vector2.ONE
	$Name/HBox/Label.text = d_name.capitalize()
	$Name/Shadow.text = d_name.capitalize()
	await get_tree().physics_frame
	await get_tree().physics_frame
	$Name.visible = true
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
			$Face/Sprite2D.flip_h = false
		"right":
			$Face/Sprite2D.flip_h = true


func change_background(node_to_show) -> bool:
	if node_to_show == $Flat:
		if $Flat.visible: return false
		elif $NPC.visible:
			$NPC.visible = false
			$AnimationPlayer.play("NPCToFlat")
			return true
	elif node_to_show == $NPC:
		if $NPC.visible: return false
		if $Flat.visible:
			$Flat.visible = false
			$AnimationPlayer.play("FlatToNPC")
			return true
	return false

func clear_text():
	dl.text = get_text_stripped_of_commands(step)
	dl.visible_characters = 0
	character_shown_count = 0
	character_is_newline_count = 0
	character_is_bbcode_count = 0

### GETTERS ###

func get_text_array_starts_with_face() -> bool:
	if current_text_array[0].containsn("/newchar") || current_text_array[0].containsn("/face"):
		return true
	else:
		return false

func get_raw_index(extra := 0) -> int:
	return character_shown_count + character_is_newline_count + character_is_bbcode_count + extra

#func convert_index

### SIGNALS ###

func _resolution_scale_changed(_resolution_scale = vs.dialog_resolution_scale):
	var viewport_size = get_tree().get_root().size / vs.dialog_resolution_scale
	#size.x = min(viewport_size.x, 400)
	position.x = (viewport_size.x - size.x) / 2.0
	#position.y = viewport_size.y - 80
