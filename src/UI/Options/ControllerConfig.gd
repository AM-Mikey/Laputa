extends Control

var input_map_path = "user://inputmap.json"
onready var world = get_tree().get_root().get_node("World")

var compass_distance = 8


onready var op_l2 = $ScrollContainer/VBoxContainer/HBoxContainer/Left/L2
onready var op_l1 = $ScrollContainer/VBoxContainer/HBoxContainer/Left/L1
onready var op_l3 = $ScrollContainer/VBoxContainer/HBoxContainer2/L3

onready var op_r2 = $ScrollContainer/VBoxContainer/HBoxContainer/Right/R2
onready var op_r1 = $ScrollContainer/VBoxContainer/HBoxContainer/Right/R1
onready var op_r3 = $ScrollContainer/VBoxContainer/HBoxContainer2/R3

onready var op_facetop = $ScrollContainer/VBoxContainer/HBoxContainer/Right/Face/Top
onready var op_faceleft = $ScrollContainer/VBoxContainer/HBoxContainer/Right/Face/Left
onready var op_faceright = $ScrollContainer/VBoxContainer/HBoxContainer/Right/Face/Right
onready var op_facebottom = $ScrollContainer/VBoxContainer/HBoxContainer/Right/Face/Bottom


onready var op_select = $ScrollContainer/VBoxContainer/HBoxContainer2/Select
onready var op_start = $ScrollContainer/VBoxContainer/HBoxContainer2/Start

onready var option_buttons = [op_l2, op_l1, op_l3, op_r2, op_r1, op_r3, op_facetop, op_faceleft, op_faceright, op_facebottom, op_select, op_start]

onready var faceleft = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer/Face/HBoxContainer/FaceButtonLeft/Sprite
onready var faceright = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer/Face/HBoxContainer/FaceButtonRight/Sprite
onready var facetop = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer/Face/FaceButtonTop/Sprite
onready var facebottom = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer/Face/FaceButtonBottom/Sprite

onready var select = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer/ScrewLeft/Sprite
onready var start = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer/ScrewRight/Sprite

onready var l1 = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Top/GridContainer/BumperLeft/Sprite
onready var r1 = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Top/GridContainer/BumperRight/Sprite
onready var l2 = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Top/GridContainer/TriggerLeft/Sprite
onready var r2 = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Top/GridContainer/TriggerRight/Sprite

onready var lstick = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer2/StickLeft/Sprite
onready var rstick = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer2/StickRight/Sprite

onready var dpad = $ScrollContainer/VBoxContainer/HBoxContainer/Center/Front/VboxContainer/HBoxContainer/Compass/CrossHair

onready var option_pairs = {
	op_l2: l2,
	op_l1: l1,
	op_l3: lstick,
	op_r2: r2,
	op_r1: r1,
	op_r3: rstick,
	op_facetop: facetop,
	op_faceleft: faceleft,
	op_faceright: faceright,
	op_facebottom: facebottom,
	op_select: select,
	op_start: start
}

onready var action_names = ["*None*", "Jump", "Manual Fire", "Automatic Fire", "Inspect", "Inventory", "Weapon Left", "Weapon Right", "Pause"]
onready var actions = [null, "jump", "fire_manual", "fire_automatic", "inspect", "inventory", "weapon_left", "weapon_right", "pause"]

func _ready():
#	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
#	_on_viewport_size_changed()
	
	for o in option_buttons:
		for a in action_names:
			o.add_item(a)
			if o.get_signal_list().size() == 0:
				o.connect("item_selected", self, "change_event", [o.name])

	set_option_buttons()


func _process(_delta):
	if Input.is_joy_button_pressed(0, JOY_DS_Y):
		faceleft.frame = 1
	else: faceleft.frame = 0
	if Input.is_joy_button_pressed(0, JOY_DS_A):
		faceright.frame = 1
	else: faceright.frame = 0
	if Input.is_joy_button_pressed(0, JOY_DS_X):
		facetop.frame = 1
	else: facetop.frame = 0
	if Input.is_joy_button_pressed(0, JOY_DS_B):
		facebottom.frame = 1
	else: facebottom.frame = 0

	if Input.is_joy_button_pressed(0, JOY_SELECT):
		if select.frame < 3:
			select.frame += 1
	else: 
		if select.frame > 0:
			select.frame -= 1
	if Input.is_joy_button_pressed(0, JOY_START):
		if start.frame < 3:
			start.frame += 1
	else: 
		if start.frame > 0:
			start.frame -= 1

	if Input.is_joy_button_pressed(0, JOY_L):
		l1.frame = 1
	else: l1.frame = 0
	if Input.is_joy_button_pressed(0, JOY_R):
		r1.frame = 1
	else: r1.frame = 0
	if Input.is_joy_button_pressed(0, JOY_L2):
		l2.frame = 1
	else: l2.frame = 0
	if Input.is_joy_button_pressed(0, JOY_R2):
		r2.frame = 1
	else: r2.frame = 0

	if Input.is_joy_button_pressed(0, JOY_L3):
		lstick.frame = 1
	else: lstick.frame = 0
	if Input.is_joy_button_pressed(0, JOY_R3):
		rstick.frame = 1
	else: rstick.frame = 0

	if Input.is_joy_button_pressed(0, JOY_DPAD_LEFT):
		if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
			dpad.position = Vector2(-1, -1) * compass_distance
		elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
			dpad.position = Vector2(-1, 1) * compass_distance
		else:
			dpad.position = Vector2.LEFT * compass_distance
	elif Input.is_joy_button_pressed(0, JOY_DPAD_RIGHT):
		if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
			dpad.position = Vector2(1, -1) * compass_distance
		elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
			dpad.position = Vector2(1, 1) * compass_distance
		else:
			dpad.position = Vector2.RIGHT * compass_distance
	elif Input.is_joy_button_pressed(0, JOY_DPAD_UP):
		dpad.position = Vector2.UP * compass_distance
	elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
		dpad.position = Vector2.DOWN * compass_distance
	else:
		dpad.position = Vector2.ZERO


func change_event(action_index, button):
	var action = actions[action_index]
	var index
	match button:
		"L2": index = JOY_L2
		"L1": index = JOY_L
		"L3": index = JOY_L3
		"R2": index = JOY_R2
		"R1": index = JOY_R
		"R3": index = JOY_R3
		"Top": index = JOY_DS_X
		"Left": index = JOY_DS_Y
		"Right": index = JOY_DS_A
		"Bottom": index = JOY_DS_B
		"Select": index = JOY_SELECT
		"Start": index = JOY_START
		
	var event = InputEventJoypadButton.new()
	event.set_button_index(index)
	
	#erase all other events that are the same button
	for a in InputMap.get_actions():
		if InputMap.action_has_event(a, event):
			InputMap.action_erase_event(a,event)
	
	#add the new event
	if action != null:
		InputMap.action_add_event(action, event)
	save_input_map()

func save_input_map():
	var data = {}
	var input_actions = InputMap.get_actions()
	for a in input_actions:
		var inputs = []
		for i in InputMap.get_action_list(a):
				if i is InputEventMouseButton:
					inputs.append(["mouse", i.button_index])
				if i is InputEventKey:
					inputs.append(["key", i.scancode])
				if i is InputEventJoypadButton:
					inputs.append(["joy", i.button_index])
		data[a] = inputs
	
	
	var file = File.new()
	var file_written = file.open(input_map_path, File.WRITE)
	if file_written == OK:
		#file.store_var(data)
		file.store_string(var2str(data))
		file.close()
		print("input map data saved")
	else:
		printerr("ERROR: input map data could not be saved!")


func load_input_map():
	var data
	
	var file = File.new()
	if file.file_exists(input_map_path):
		var file_read = file.open(input_map_path, File.READ)
		if file_read == OK:
			var text = file.get_as_text()
			data = JSON.parse(text).result
			#data = file.get_var()
			file.close()
			
			for a in data.keys():
				InputMap.action_erase_events(a)
				for i in data[a]:
					var new_input
					match i.front():
						"mouse":
							new_input = InputEventMouseButton.new()
							new_input.set_button_index(i.back())
						"key":
							new_input = InputEventKey.new()
							new_input.set_scancode(i.back())
						"joy":
							new_input = InputEventJoypadButton.new()
							new_input.set_button_index(i.back())

					InputMap.action_add_event(a, new_input)

	else: 
		printerr("ERROR: could not load input map data")


func set_option_buttons():
	for o in option_buttons:
		var index
		match o.name:
			"L2": index = JOY_L2
			"L1": index = JOY_L
			"L3": index = JOY_L3
			"R2": index = JOY_R2
			"R1": index = JOY_R
			"R3": index = JOY_R3
			"Top": index = JOY_DS_X
			"Left": index = JOY_DS_Y
			"Right": index = JOY_DS_A
			"Bottom": index = JOY_DS_B
			"Select": index = JOY_SELECT
			"Start": index = JOY_START
	
		var event = InputEventJoypadButton.new()
		event.set_button_index(index)
		
		for a in InputMap.get_actions():
			if InputMap.action_has_event(a, event): 
				if not actions.find(a) == -1: #finds the action index on the optionbutton or returns -1 if null
					o.select(actions.find(a))
				else:
					o.select(0)


#func _on_viewport_size_changed():
#	var offset = Vector2(0,0) #we only need this since the position gets offset for some reason
#
#	for c in $Lines.get_children():
#		c.free()
#	for k in option_pairs.keys():
#		var line = Line2D.new()
#		line.default_color = Color.white
#		line.width = 2
#		line.add_point(k.rect_global_position + offset)
#		line.add_point(option_pairs[k].global_position + offset)
#		$Lines.add_child(line)


func _on_Default_pressed():
	pass # Replace with function body.


func _on_Return_pressed():
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").visible = true
		world.get_node("UILayer/PauseMenu").focus()
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").visible = true
		world.get_node("UILayer/TitleScreen").focus()
		
	if world.has_node("UILayer/Options"):
		world.get_node("UILayer/Options").queue_free()
	else:
		get_parent().queue_free()

func focus():
	op_l2.grab_focus()
