extends Control

const CONTROLLERCONFIG = preload("res://src/UI/Options/ControllerConfig.tscn")

var input_map_path = "user://inputmap.json"

var assignment_mode = false
var button_ignore = false
var action_string
var actions = []
var debug_actions = []

var active_preset = 0

@export var buttons: NodePath
@onready var p_button = get_node(buttons)
@export var ui_focus: NodePath
@export var preset_path: NodePath

@onready var world = get_tree().get_root().get_node("World")

var preset_classic = {
	"jump": KEY_X,
	"fire_manual": KEY_C,
	"fire_automatic": KEY_Z,
	"move_left": KEY_LEFT,
	"move_right": KEY_RIGHT,
	"look_up": KEY_UP,
	"look_down": KEY_DOWN,
	"ui_accept": KEY_X,
	"ui_cancel": KEY_C,
	"inspect": KEY_DOWN,
	"inventory": KEY_Q,
	"gun_left": KEY_A,
	"gun_right": KEY_S,
	"pause": KEY_ESCAPE,
}

var preset_mouse = {
	"jump": KEY_SPACE,
	"fire_manual": MOUSE_BUTTON_LEFT,
	"fire_automatic": MOUSE_BUTTON_RIGHT,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"look_up": KEY_W,
	"look_down": KEY_S,
	"ui_accept": KEY_E,
	"ui_cancel": KEY_Q,
	"inspect": KEY_E,
	"inventory": KEY_TAB,
	"gun_left": MOUSE_BUTTON_WHEEL_DOWN,
	"gun_right": MOUSE_BUTTON_WHEEL_UP,
	"pause": KEY_ESCAPE,
}

var preset_onehand = {
	"jump": KEY_SHIFT,
	"fire_manual": KEY_SPACE,
	"fire_automatic": KEY_ALT,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"look_up": KEY_W,
	"look_down": KEY_S,
	"ui_accept": KEY_SPACE,
	"ui_cancel": KEY_ESCAPE,
	"inspect": KEY_S,
	"inventory": KEY_TAB,
	"gun_left": KEY_Q,
	"gun_right": KEY_E,
	"pause": KEY_ESCAPE,
}


func _ready():
	get_node(preset_path).select(0)
	var buttons_normal = []
	
	for c in p_button.get_children():
		var subchildren = c.get_children()
		for s in subchildren:
			if s is Button:
				buttons_normal.append(s)

	for b in buttons_normal:
		b.connect("pressed", Callable(self, "_mark_button").bind(b.get_parent().name))
		actions.append(b.get_parent().name)

	_set_keys()



func _set_keys():
	for j in actions:
		var button = p_button.get_node(str(j) + "/Button")
		button.set_pressed(false)
		
		if InputMap.action_get_events(j).is_empty():
			button.set_text("No Button!")
			#button.set_pressed(false)
			return
		
		var input = _get_first_valid_input(j)
		if input != null:
			if input is InputEventKey:
				button.set_text(input.as_text())
			elif input is InputEventMouseButton:
				var mouse_index
				match input.button_index:
					1: mouse_index = "LMB"
					2: mouse_index = "RMB"
					3: mouse_index = "MMB"
					4: mouse_index = "MWHEELUP"
					5: mouse_index = "MWHEELDOWN"
					6: mouse_index = "MWHEELLEFT"
					7: mouse_index = "MWHEELRIGHT"
					8: mouse_index = "M4"
					9: mouse_index = "M5"
				button.set_text(mouse_index)
			
#			print("/////////////")
#			print ("input" + str(input))
#			print(_get_first_valid_input("ui_accept"))
#			if input == _get_first_valid_input("ui_accept"): #toggle off the button if we're not pressing our ui_accept
#				print("bingo")
##			else:
#			button.set_pressed(false)


  
func _get_first_valid_input(j):
			var index = 0
			var good_input = InputMap.action_get_events(j)[index]
			while not good_input is InputEventKey and not good_input is InputEventMouseButton and index < InputMap.action_get_events(j).size() - 1:
				index +=1
				good_input = InputMap.action_get_events(j)[index]
			
			if not good_input is InputEventKey and not good_input is InputEventMouseButton:
				return null
			else:
				return good_input



func _mark_button(string):
	if button_ignore:
		button_ignore = false
		
		for j in actions:
			if j == string:
				p_button.get_node(str(j) + "/Button").set_pressed(false)
		
	else:
		assignment_mode = true
		action_string = string
		
		for j in actions:
			if j != string:
				p_button.get_node(str(j) + "/Button").set_pressed(false)



func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and assignment_mode:
		print("second_input")
		_change_key(event)
		assignment_mode = false
		
		var accept_input_event = _get_first_valid_input("ui_accept") #prevent us from entering another assignment mode when event is accept_event
		if event is InputEventKey and accept_input_event is InputEventKey:
			if event.keycode == accept_input_event.keycode:
				button_ignore = true
		if event is InputEventMouseButton and accept_input_event is InputEventMouseButton:
			if event.button_index == accept_input_event.button_index:
				button_ignore = true



func _change_key(new_key):
	get_node(preset_path).select(0)
	
	#Delete key of pressed button
	if !InputMap.action_get_events(action_string).is_empty():
		var input = _get_first_valid_input(action_string)
		if input != null:
			InputMap.action_erase_event(action_string, input)
	
	#Check if new key was assigned somewhere 		#pass for now
#	var all_actions = actions + debug_actions
#	for i in all_actions:
#		if InputMap.action_has_event(i, new_key):
#			InputMap.action_erase_event(i, new_key)
			
			
	#Add new Key
	InputMap.action_add_event(action_string, new_key)
	
	
	#alias action
	var alias_action_string
	match action_string:
		"move_left": alias_action_string = "ui_left"
		"move_right": alias_action_string = "ui_right"
		"look_up": alias_action_string = "ui_up"
		"look_down": alias_action_string = "ui_down"

	if alias_action_string != null:
		if !InputMap.action_get_events(alias_action_string).is_empty():
			var input = _get_first_valid_input(alias_action_string)
			if input != null:
				InputMap.action_erase_event(alias_action_string, input)
		InputMap.action_add_event(alias_action_string, new_key)
	
	###
	
	save_input_map()
	_set_keys()



func save_input_map():
	var data = {}
	var input_actions = InputMap.get_actions()
	for a in input_actions:
		var inputs = []
		for i in InputMap.action_get_events(a):
				if i is InputEventMouseButton:
					inputs.append(["mouse", i.button_index])
				if i is InputEventKey:
					inputs.append(["key", i.keycode])
				if i is InputEventJoypadButton:
					inputs.append(["joy", i.button_index])
		data[a] = inputs
	
	
	var file = FileAccess.open(input_map_path, FileAccess.WRITE)
	if file:
		file.store_string(var_to_str(data))
		file.close()
		print("input map data saved")
	else:
		printerr("ERROR: input map data could not be saved!")


func load_input_map():
	var data
	if FileAccess.file_exists(input_map_path):
		var file = FileAccess.open(input_map_path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var test_json_conv = JSON.new()
			test_json_conv.parse(text)
			data = test_json_conv.get_data()
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
							new_input.set_keycode(i.back())
						"joy":
							new_input = InputEventJoypadButton.new()
							new_input.set_button_index(i.back())

					InputMap.action_add_event(a, new_input)

	else: 
		printerr("ERROR: could not load input map data")


func _on_preset_selected(index):
	get_node(preset_path).select(active_preset)
	if index != 0:
		active_preset = index
		$ConfirmationDialog.popup()

func _on_ConfirmationDialog_confirmed():
	get_node(preset_path).select(active_preset)
	match active_preset:
		1: set_preset(preset_classic)
		2: set_preset(preset_mouse)
		3: set_preset(preset_onehand)

func set_preset(preset):
	for k in preset.keys():
		#Delete key of pressed button
		if !InputMap.action_get_events(k).is_empty():
			var old_input = _get_first_valid_input(k)
			if old_input:
				InputMap.action_erase_event(k, old_input)

		#Add new key
		var new_input
		if preset[k] <= 10: #TODO: not a great way to determine if a key enum is a key or mouse
			new_input = InputEventMouseButton.new()
			new_input.button_index = preset[k]
		else:
			new_input = InputEventKey.new()
			new_input.keycode = preset[k]
		InputMap.action_add_event(k, new_input)
	

		#Alias action
		var alias_action_string
		match k:
			"move_left": alias_action_string = "ui_left"
			"move_right": alias_action_string = "ui_right"
			"look_up": alias_action_string = "ui_up"
			"look_down": alias_action_string = "ui_down"
			
		if alias_action_string:
			if !InputMap.action_get_events(alias_action_string).is_empty():
				var old_input = _get_first_valid_input(alias_action_string)
				if old_input:
					InputMap.action_erase_event(alias_action_string, old_input)
			InputMap.action_add_event(alias_action_string, new_input)
	
	
	save_input_map()
	_set_keys()



func _on_Return_pressed():
	if world.has_node("UILayer/UIGroup/PauseMenu"):
		world.get_node("UILayer/UIGroup/PauseMenu").visible = true
		world.get_node("UILayer/UIGroup/PauseMenu").do_focus()
	if world.has_node("UILayer/UIGroup/TitleScreen"):
		world.get_node("UILayer/UIGroup/TitleScreen").visible = true
		world.get_node("UILayer/UIGroup/TitleScreen").do_focus()
		
	if world.has_node("UILayer/UIGroup/Options"):
		world.get_node("UILayer/UIGroup/Options").queue_free()
	else:
		get_parent().queue_free()


func do_focus():
	get_node(ui_focus).grab_focus()
