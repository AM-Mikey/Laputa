extends Area2D

const WAYPOINT_GLOBAL = preload("res://src/Editor/WaypointGlobal.tscn")

#@export var properties = {}
@export var tag_name: String
@export var index: int = 0

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	if w.el.get_child_count() == 0: #not in editor
		visible = false
		input_pickable = false
		spawn()

func initialize(): #first time set up properties
	pass
	#var actor = load(actor_path).instantiate()
	#for p in actor.get_property_list():
		#if p["usage"] == 4102 || p["usage"] == 69638: #exported properties
			#properties[p["name"]] = [actor.get(p["name"]), p["type"]]
	#for c in actor.get_children():
		#if c.is_in_group("WaypointLocals"):
			#if !get_if_actor_has_waypoint(c):
				#actor.remove_child(c)
				#add_child(c)
				#c.owner = w.current_level
	#actor.free()

func reinitialize(): #makes sure properties are up to date and in the right order without deleting old values
	pass
	#var old_properties = properties
	#properties = {}
	#var actor = load(actor_path).instantiate()
	#for p in actor.get_property_list():
		#if p["usage"] == 4102 || p["usage"] == 69638: #exported properties
			#if old_properties.has(p["name"]):
				#properties[p["name"]] = old_properties[p["name"]]
			#else:
				#properties[p["name"]] = [actor.get(p["name"]), p["type"]]
	#for c in actor.get_children():
		#if c.is_in_group("WaypointLocals"):
			#if !get_if_actor_has_waypoint(c):
				#actor.remove_child(c)
				#add_child(c)
				#c.owner = w.current_level
	#actor.free()


func spawn():
	print("spawnwaypoint") #somehow spawns more than one of these if it's not the starting position #TODO
	var saved_pos = global_position
	var waypoint_global = WAYPOINT_GLOBAL.instantiate()
	waypoint_global.global_position = saved_pos
	if "id" in get_parent():
		waypoint_global.owner_id = get_parent().id #TODO: force enemies to get an ID
	else:
		waypoint_global.owner_id = get_parent().properties["id"][0]
	waypoint_global.index = index
	waypoint_global.uses_spawn = true
	w.current_level.get_node("Waypoints").add_child(waypoint_global)


### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)


#func on_pressed(): #when
	#emit_signal("selected", self, "actor_spawn")

func _input_event(_viewport, event, _shape_idx): #selecting in editor
	var inspector = w.get_node("EditorLayer/Editor").inspector
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		inspector.on_selected(self, "waypoint_global_spawn")
