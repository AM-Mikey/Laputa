extends MarginContainer


onready var world = get_tree().get_root().get_node("World")
var hidden = false

func _ready():
	if hidden:
		visible = false
	else:
		$TabContainer/Settings.focus()
		var _err = get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
		_on_viewport_size_changed()


func _on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale


func _on_TabContainer_tab_changed(tab):
	match tab:
		0: $TabContainer/Settings.focus()
		1: $TabContainer/KeyConfig.focus()
		2: $TabContainer/ControllerConfig.focus()

func _input(event):
	if event.is_action_pressed("weapon_left"):
		if $TabContainer.current_tab == 0:
			$TabContainer.current_tab = 2
		else:
			$TabContainer.current_tab -= 1
		
	if event.is_action_pressed("weapon_right"):
		if $TabContainer.current_tab == 2:
			$TabContainer.current_tab = 0
		else:
			$TabContainer.current_tab += 1
	
#	if event.is_action_pressed("ui_cancel"):
#
#		if world.has_node("UILayer/PauseMenu"):
#			world.get_node("UILayer/PauseMenu").focus()
#		if world.has_node("UILayer/TitleScreen"):
#			world.get_node("UILayer/TitleScreen").focus()
#		else:
#			queue_free()
