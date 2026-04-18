extends MarginContainer

var allow_spawn := true
var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

@export_file var trigger_path
@export var properties = {}
@export var size_is_default = true

@onready var world = get_tree().get_root().get_node("World")

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
	#transform
	if size_is_default:
		size = trigger.get_node("CollisionShape2D").shape.size
		size_is_default = false
	#global_position = trigger.get_node("CollisionShape2D").global_position

	if world.el.get_child_count() == 0: #not in editor
		visible = false
		spawn()

	for section in $Handles.get_children():
		for button in section.get_children():
			if !(button.button_down.is_connected(on_handle)):
				button.connect("button_down", Callable(self, "on_handle").bind(button))
			buttons.append(button)



func initialize(): #first time set up properties
	var trigger = load(trigger_path).instantiate()
	for p in trigger.get_property_list():
		if p["usage"] == 4102: #exported properties
			properties[p["name"]] = [trigger.get(p["name"]), p["type"]]
		elif p["usage"] == 69638: #exported property enums
			properties[p["name"]] = [trigger.get(p["name"]), p["type"]]
	properties["id"] = [name, TYPE_STRING]
	for ac in trigger.get_children(): #TODO: add these to props and to waypoints
		if ac.is_in_group("WaypointLocals"):
			if !get_if_trigger_has_waypoint(ac):
				trigger.remove_child(ac)
				add_child(ac)
				ac.owner = world.current_level
		if ac.is_in_group("WaypointGlobalSpawns"):
			if !get_if_trigger_has_waypoint(ac):
				trigger.remove_child(ac)
				add_child(ac)
				ac.owner = world.current_level
		if ac.is_in_group("ToolVectors"):
			if !get_if_trigger_has_tool_vector(ac):
				trigger.remove_child(ac)
				add_child(ac)
				ac.owner = world.current_level
		if ac.is_in_group("ToolRects"):
			if !get_if_trigger_has_tool_rect(ac):
				trigger.remove_child(ac)
				add_child(ac)
				ac.owner = world.current_level
	trigger.free()

func reinitialize(): #makes sure properties are up to date and in the right order without deleting old values
	var old_properties = properties
	properties = {}
	var trigger = load(trigger_path).instantiate()
	for p in trigger.get_property_list():
		if p["usage"] == 4102 || p["usage"] == 69638: #exported properties
			if old_properties.has(p["name"]):
				properties[p["name"]] = old_properties[p["name"]]
			else:
				properties[p["name"]] = [trigger.get(p["name"]), p["type"]]
	for ac in trigger.get_children():
		if ac.is_in_group("WaypointLocals"):
			if !get_if_trigger_has_waypoint(ac):
				trigger.remove_child(ac)
				add_child(ac)
				ac.owner = world.current_level
		if ac.is_in_group("ToolVectors"):
			if !get_if_trigger_has_tool_vector(ac):
				trigger.remove_child(ac)
				add_child(ac)
				ac.owner = world.current_level
		if ac.is_in_group("ToolRects"):
			if !get_if_trigger_has_tool_rect(ac):
				trigger.remove_child(ac)
				add_child(ac)
				ac.owner = world.current_level

	trigger.free()

func spawn():
	await get_tree().process_frame #wait to set allow_spawn
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
		if ac.is_in_group("WaypointLocals") || ac.is_in_group("ToolVectors") || ac.is_in_group("ToolRects"):
			trigger.remove_child(ac)
		if ac.is_in_group("WaypointGlobalSpawns"): #turn off visibility
			ac.visible = false

	for c in get_children(): #add new from spawn
		if c.is_in_group("WaypointLocals") || c.is_in_group("ToolVectors") || c.is_in_group("ToolRects"):
			var copy = c.duplicate()
			trigger.add_child(copy)

	world.current_level.get_node("Triggers").call_deferred("add_child", trigger)

func _input(event):
	if event.is_action_released("editor_lmb"):
		state = "idle"
		return
	if event is InputEventMouseMotion and state != "idle": #dragging or resizing
		var x = snapped(get_global_mouse_position().x + drag_offset.x, 8)
		var y = snapped(get_global_mouse_position().y + drag_offset.y, 8)

		var parent_x = get_parent().position.x
		var parent_y = get_parent().position.y

		match state:
			"drag":
				#var tile_map = world.current_level.get_node("TileMap")
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

func get_if_trigger_has_tool_vector(trigger_tool_vector) -> bool:
	for c in get_children():
		if c.is_in_group("ToolVectors"):
			if c.tag_name == trigger_tool_vector.tag_name:
				return true
	return false

func get_if_trigger_has_tool_rect(trigger_tool_rect) -> bool:
	for c in get_children():
		if c.is_in_group("ToolRects"):
			if c.tag_name == trigger_tool_rect.tag_name:
				return true
	return false

### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)


func on_handle(handle):
	if handle.name != "Mid":
		state = "resize"
		active_handle = handle
		drag_offset = handle.global_position - get_global_mouse_position()
	else:
		state = "drag"
		drag_offset = global_position - get_global_mouse_position()

	var inspector = world.get_node("EditorLayer/Editor").inspector
	inspector.on_selected(self, "trigger_spawn")
