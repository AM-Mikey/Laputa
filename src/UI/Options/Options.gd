extends MarginContainer


@onready var world = get_tree().get_root().get_node("World")
var ishidden = false

@onready var tabs = $VBoxContainer2/TabContainer

func _ready():
	if ishidden:
		visible = false
	else:
		tabs.get_node("Settings").ignore_display_mode = true
		tabs.get_node("Settings").do_focus()
		if world.has_node("MenuLayer/TitleScreen"):
			world.get_node("MenuLayer/TitleScreen").visible = false
		if world.has_node("MenuLayer/PauseMenu"):
			world.get_node("MenuLayer/PauseMenu").visible = false
		%TabContainer.set_tab_title(0, "Main")
		%TabContainer.set_tab_title(1, "Keyboard")
		%TabContainer.set_tab_title(2, "Controller")
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


#func _input(event):
	#if event.is_action_pressed("gun_left"):
		#if tabs.current_tab == 0:
			#tabs.current_tab = 2
		#else:
			#tabs.current_tab -= 1
#
	#if event.is_action_pressed("gun_right"):
		#if tabs.current_tab == 2:
			#tabs.current_tab = 0
		#else:
			#tabs.current_tab += 1


func exit():
	if world.has_node("MenuLayer/PauseMenu"):
		world.get_node("MenuLayer/PauseMenu").visible = true
		world.get_node("MenuLayer/PauseMenu").do_focus()
	if world.has_node("MenuLayer/TitleScreen"):
		world.get_node("MenuLayer/TitleScreen").visible = true
		world.get_node("MenuLayer/TitleScreen").do_focus()
	queue_free()



### SIGNALS ###

func _on_TabContainer_tab_changed(tab):
	match tab:
		0: tabs.get_node("Settings").do_focus()
		1: tabs.get_node("KeyConfig").do_focus()
		2: tabs.get_node("ControllerConfig").do_focus()

func _resolution_scale_changed(_resolution_scale):
	size = get_tree().get_root().size / vs.menu_resolution_scale
