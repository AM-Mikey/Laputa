extends MarginContainer

const NPC_BUTTON = preload("res://src/Editor/Button/NPCButton.tscn")

signal npc_changed(npc_path)

var icon = "res://assets/Icon/NPCIcon.png"
var npcs = {}
var active_npc_path

onready var editor = get_parent().get_parent().get_parent()

func _ready():
	setup_npcs()


func setup_npcs():
	var index = 0
	for p in find_npc_scenes("res://src/Actor/NPC/"):
		
		var npc = load(p).instance()
		
		npcs[npc.name] = npc
		
		var npc_button = NPC_BUTTON.instance()
		npc_button.npc_path = p
		npc_button.npc_name = npc.name
		npc_button.connect("npc_changed", self, "on_npc_changed")
		if index == 0:
			npc_button.active = true
			active_npc_path = p
		$VBox/Margin/Scroll/Buttons.add_child(npc_button)
		index += 1
		

### GETTERS

func find_npc_scenes(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".tscn"):
			files.append(path + file)
			
	return files

### SIGNALS

func on_npc_changed(npc_path):
	editor.set_tool("entity", "npc")
	active_npc_path = npc_path
	for b in $VBox/Margin/Scroll/Buttons.get_children():
		if b.npc_path == active_npc_path: #this is weird, we should have already done this. for extra security in case it was activated another way?
			b.activate()
	
	emit_signal("npc_changed", npc_path)
