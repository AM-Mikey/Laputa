extends MarginContainer


@onready var world = get_tree().get_root().get_node("World")
var ishidden = false

@onready var tabs = $VBoxContainer2/TabContainer

func _ready():
	if ishidden:
		visible = false
	else:
		tabs.get_node("Settings").do_focus()
		if world.has_node("UILayer/TitleScreen"):
			world.get_node("UILayer/TitleScreen").visible = false
		var _err = get_tree().root.connect("size_changed", Callable(self, "_on_viewport_size_changed"))
		_on_viewport_size_changed()


func _on_viewport_size_changed():
	size = get_tree().get_root().size / world.resolution_scale


func _on_TabContainer_tab_changed(tab):
	match tab:
		0: tabs.get_node("Settings").do_focus()
		1: tabs.get_node("KeyConfig").do_focus()
		2: tabs.get_node("ControllerConfig").do_focus()

func _input(event):
	if event.is_action_pressed("gun_left"):
		if tabs.current_tab == 0:
			tabs.current_tab = 2
		else:
			tabs.current_tab -= 1

	if event.is_action_pressed("gun_right"):
		if tabs.current_tab == 2:
			tabs.current_tab = 0
		else:
			tabs.current_tab += 1



func _on_Return_pressed():
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").visible = true
		world.get_node("UILayer/PauseMenu").do_focus()
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").visible = true
		world.get_node("UILayer/TitleScreen").do_focus()
		
	queue_free()
