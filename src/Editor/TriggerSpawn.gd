extends MarginContainer

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

@export_file var trigger_path
@export var properties = {}

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
	if index == 0:
		name = trigger.name
	else:
		name = str(trigger.name, index)
	
	#transform
	#size = trigger.get_node("CollisionShape2D").shape.size
	#global_position = trigger.get_node("CollisionShape2D").global_position

	if world.el.get_child_count() == 0: #not in editor
		visible = false
		spawn()


	for h in $Handles/Top.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
			buttons.append(h)
	for h in $Handles/Mid.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
			buttons.append(h)
	for h in $Handles/Bottom.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
			buttons.append(h)



func initialize(): #first time set up properties
	var trigger = load(trigger_path).instantiate()
	for p in trigger.get_property_list():
		if p["usage"] == 4102: #exported properties
			properties[p["name"]] = [trigger.get(p["name"]), p["type"]]

func spawn():
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
	
	world.current_level.get_node("Triggers").call_deferred("add_child", trigger)



func _input(event):
	if event.is_action_released("editor_lmb"):
		state = "idle"
		return
	if event is InputEventMouseMotion and state != "idle": #dragging or resizing
		var x = snapped(get_global_mouse_position().x + drag_offset.x, 16)
		var y = snapped(get_global_mouse_position().y + drag_offset.y, 16)
		
		var parent_x = get_parent().position.x
		var parent_y = get_parent().position.y
		
		match state:
			"drag":
				var tile_map = world.current_level.get_node("TileMap")
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
	emit_signal("selected", get_parent(), "trigger")
	
	
	var inspector = world.get_node("EditorLayer/Editor").inspector
	inspector.on_selected(self, "trigger_spawn")
