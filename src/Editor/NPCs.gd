extends MarginContainer

const NPC_BUTTON = preload("res://src/Editor/Button/NPCButton.tscn")

signal npc_changed(npc_path)

var npcs = {}
var active_npc_path

@onready var editor = get_parent().get_parent().get_parent().get_parent()



func _ready():
	setup_npcs()

func setup_npcs(): #TODO: connect this to editor instead of _ready
	editor.connect("tab_changed", Callable(self, "on_tab_changed"))
	var index = 0
	for p in find_npc_scenes("res://src/Actor/NPC/"):

		var npc = load(p).instantiate()
		if not npc.editor_hidden:
			npcs[npc.name] = npc

			var npc_button = NPC_BUTTON.instantiate()
			npc_button.npc_path = p
			npc_button.npc_name = npc.name
			npc_button.npc_sprite = npc.get_node("Sprite2D").texture
			npc_button.connect("npc_changed", Callable(self, "change_npc"))
			if index == 0:
				npc_button.active = true
				active_npc_path = p
			$VBox/Margin/Scroll/Buttons.add_child(npc_button)
			index += 1


### GETTERS

func find_npc_scenes(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".tscn"):
			files.append(path + file)

	return files

func change_npc(npc_path):
	editor.set_tool("entity", "npc")
	active_npc_path = npc_path

func unpick_npc():
	active_npc_path = null
	for b in $VBox/Margin/Scroll/Buttons.get_children():
			b.deactivate()



### SINGALS ###

func on_tab_changed(tab_name):
	pass
