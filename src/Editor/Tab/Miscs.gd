extends MarginContainer

const MISC_BUTTON = preload("res://src/Editor/Button/MiscButton.tscn")
const MISC_SCENES = [
	"res://src/Editor/WaypointLocal.tscn",
	"res://src/Editor/WaypointGlobal.tscn",
	"res://src/Editor/SpawnPoint.tscn",
	"res://src/Editor/VanishingPoint.tscn",
]

signal misc_changed(misc_path)

var miscs = {}
var active_misc_path

@onready var editor = get_parent().get_parent().get_parent().get_parent()


func setup_miscs():
	editor.connect("tab_changed", Callable(self, "on_tab_changed"))
	var index = 0
	for m in MISC_SCENES:
		var misc = load(m).instantiate()
		miscs[misc.name] = misc
		var misc_button = MISC_BUTTON.instantiate()
		misc_button.misc_path = m
		misc_button.misc_name = misc.name
		misc_button.connect("misc_changed", Callable(self, "on_misc_changed"))
		if index == 0:
			misc_button.active = true
			active_misc_path = m
		$VBox/Margin/Scroll/Buttons.add_child(misc_button)
		index += 1



### SIGNALS

func on_misc_changed(misc_path):
	editor.set_tool("entity", "misc")
	active_misc_path = misc_path
	for b in $VBox/Margin/Scroll/Buttons.get_children():
		if b.misc_path == active_misc_path: #this is weird, we should have already done this. for extra security in case it was activated another way?
			b.activate()
	emit_signal("misc_changed", misc_path)

func on_tab_changed(_tab_name):
	pass
