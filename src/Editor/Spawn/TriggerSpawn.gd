extends MarginContainer

@export_file var trigger_path
@export var properties = {}
@export var size_is_default = true

var allow_spawn := true
var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

@onready var w = get_tree().get_root().get_node("World")

var buttons = []

func _ready():
	if trigger_path == null:
		printerr("ERROR: no trigger chosen in TriggerSpawn")
		return

	#ColorRect
	var trigger = load(trigger_path).instantiate()
	$ColorRect.color = trigger.color
	#name
	var index = 0
	for a in get_tree().get_nodes_in_group("TriggerSpawns"):
		if a == self: break
		if a.trigger_path == trigger_path:
			index +=1
	if index == 0: name = trigger.name
	else: name = str(trigger.name, index)
	#Label
	$Label.text = trigger.name
	#transform
	if size_is_default:
		size = trigger.get_node("CollisionShape2D").shape.size
		size_is_default = false
	#global_position = trigger.get_node("CollisionShape2D").global_position

	if w.el.get_child_count() == 0: #not in editor
		visible = false

	for section in $Handles.get_children():
		for button in section.get_children():
			if !(button.button_down.is_connected(on_handle)):
				button.connect("button_down", Callable(self, "on_handle").bind(button))
			buttons.append(button)

func initialize(): #first time set up properties
	var trigger = load(trigger_path).instantiate()
	for p in trigger.get_property_list():
		if p["usage"] & 4102 == 4102: #exported properties
			properties[p["name"]] = [trigger.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]
	properties["id"] = [name, TYPE_STRING, ""]

	for ac in trigger.get_children(): #TODO: add these to props and to waypoints
		if ac.is_in_group("WaypointLocals"):
			if !get_if_trigger_has_waypoint(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("WaypointGlobalSpawns"):
			if !get_if_trigger_has_waypoint(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUVectors"):
			if !get_if_trigger_has_vu_vector(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VURects"):
			if !get_if_trigger_has_vu_rect(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUActors"):
			if !get_if_trigger_has_vu_actor(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
	trigger.free()

func reinitialize(): #makes sure properties are up to date and in the right order without deleting old values
	var old_properties = properties
	properties = {}
	var trigger = load(trigger_path).instantiate()
	for p in trigger.get_property_list():
		if p["usage"] & 4102 == 4102: #exported properties
			if old_properties.has(p["name"]):
				if (old_properties[p["name"]].size() == 2): #Backward compability
					old_properties[p["name"]].append("")
				properties[p["name"]] = old_properties[p["name"]]
			else:
				properties[p["name"]] = [trigger.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]
	for ac in trigger.get_children():
		if ac.is_in_group("WaypointLocals"):
			if !get_if_trigger_has_waypoint(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUVectors"):
			if !get_if_trigger_has_vu_vector(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VURects"):
			if !get_if_trigger_has_vu_rect(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUActors"):
			if !get_if_trigger_has_vu_actor(ac):
				trigger.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level

	trigger.free()

func spawn():
	if !allow_spawn: return
	if trigger_path == null:
		printerr("ERROR: no trigger chosen in TriggerSpawn")
		return

	var trigger = load(trigger_path).instantiate()
	for p in properties:
		trigger.set(p, properties[p][0])
	trigger.name = name
	trigger.global_position = global_position
	var new_shape = RectangleShape2D.new()
	new_shape.size = size
	trigger.get_node("CollisionShape2D").shape = new_shape
	trigger.get_node("CollisionShape2D").position = new_shape.size * 0.5

	for ac in trigger.get_children(): #clear old from trigger
		if ac.is_in_group("WaypointLocals") || ac.is_in_group("VUVectors") || ac.is_in_group("VURects") || ac.is_in_group("VUActors"):
			trigger.remove_child(ac)
		if ac.is_in_group("WaypointGlobalSpawns"): #turn off visibility
			ac.visible = false

	for c in get_children(): #add new from spawn
		if c.is_in_group("WaypointLocals") || c.is_in_group("VUVectors") || c.is_in_group("VURects") || c.is_in_group("VUActors"):
			var copy = c.duplicate()
			trigger.add_child(copy)

	w.current_level.get_node("Triggers").call_deferred("add_child", trigger)

func _input(event):
	if !w.has_node("EditorLayer/Editor"): return
	var editor = w.get_node("EditorLayer/Editor")
	if editor.active_tool == "tile": return

	if event.is_action_released("editor_rmb") && state != "idle":
		var inspector = w.get_node("EditorLayer/Editor").inspector
		inspector.on_selected(self, "trigger_spawn")
		state = "idle"
		editor.active_tool = editor.pre_grab_tool
		editor.subtool = editor.pre_grab_subtool
		return

	if event is InputEventMouseMotion and state != "idle": #dragging or resizing
		var x = snapped(get_global_mouse_position().x + drag_offset.x, 8)
		var y = snapped(get_global_mouse_position().y + drag_offset.y, 8)
		var parent_x = get_parent().position.x
		var parent_y = get_parent().position.y
		match state:
			"drag":
				global_position = Vector2(x, y)
			"resize":
				match active_handle.name:
					"TopLeft":
						offset_top = y - parent_y
						offset_left = x - parent_x
					"TopRight":
						offset_top = y - parent_y
						offset_right = x - parent_x
					"BottomLeft":
						offset_bottom = y - parent_y
						offset_left = x - parent_x
					"BottomRight":
						offset_bottom = y - parent_y
						offset_right = x - parent_x
					"Top":
						offset_top = y - parent_y
					"Bottom":
						offset_bottom = y - parent_y
					"Left":
						offset_left = x - parent_x
					"Right":
						offset_right = x - parent_x

### GETTERS

func get_if_trigger_has_waypoint(trigger_waypoint) -> bool:
	var out = false
	for c in get_children():
		if c.is_in_group("WaypointLocals"): #q: does this need to apply for global spawns as well?
			if c.tag_name == trigger_waypoint.tag_name:
				out = true
	return out

func get_if_trigger_has_vu_vector(trigger_vu_vector) -> bool:
	for c in get_children():
		if c.is_in_group("VUVectors"):
			if c.tag_name == trigger_vu_vector.tag_name:
				return true
	return false

func get_if_trigger_has_vu_rect(trigger_vu_rect) -> bool:
	for c in get_children():
		if c.is_in_group("VURects"):
			if c.tag_name == trigger_vu_rect.tag_name:
				return true
	return false

func get_if_trigger_has_vu_actor(actor_vu_act) -> bool:
	for c in get_children():
		if c.is_in_group("VUActors"):
			if c.tag_name == actor_vu_act.tag_name:
				return true
	return false

### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)
	%Mid.disabled = false

func on_editor_deselect():
	modulate = Color(1,1,1,.75)
	%Mid.disabled = true

func on_handle(handle):
	var editor = w.get_node("EditorLayer/Editor")
	if editor.active_tool == "tile": return

	if handle.name != "Mid":
		state = "resize"
		editor.pre_grab_tool = editor.active_tool
		editor.pre_grab_subtool = editor.subtool
		editor.set_tool("entity", "triggerresize")
		active_handle = handle
		drag_offset = handle.global_position - get_global_mouse_position()
	else:
		state = "drag"
		editor.pre_grab_tool = editor.active_tool
		editor.pre_grab_subtool = editor.subtool
		editor.set_tool("entity", "triggergrab")
		drag_offset = global_position - get_global_mouse_position()

	var inspector = w.get_node("EditorLayer/Editor").inspector
	inspector.on_selected(self, "trigger_spawn")

func on_property_changed(p_name, p_value):
	match p_name:
		"enemy_path":
			for c in get_children():
				if c.is_in_group("VUActors"):
					for ac in c.get_children():
						if ac.is_in_group("WaypointLocals") or ac.is_in_group("WaypointGlobalSpawns") \
						or ac.is_in_group("VUVectors") or ac.is_in_group("VURects") or ac.is_in_group("VUActors"):
							ac.queue_free()
					c.actor_path = p_value
					return
