extends MarginContainer

const RETURN_ICON = preload("res://assets/UI/Options/IconReturn.png")
const LEFT_ARROW = preload("res://assets/UI/Options/ArrowLeft.png")
const RIGHT_ARROW = preload("res://assets/UI/Options/ArrowRight.png")

@onready var world = get_tree().get_root().get_node("World")
var ishidden = false
var exit_time := 1.0
var arrow_time := 0.4

@onready var tabs = $VBoxContainer2/TabContainer

func _ready():
	if ishidden:
		visible = false
	else:
		display_return_icon()
		display_arrow_icon()
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


func _physics_process(_delta):
	if !%ExitTimer.is_stopped():
		var percent_elapsed = (exit_time - %ExitTimer.time_left) / exit_time
		var time_elapsed_in_sixteenths: int = clamp(round(remap(percent_elapsed, 0.0, 1.0, 0.0, 16.0)), 0, 16)
		display_return_icon(time_elapsed_in_sixteenths)
		%ExitDecayTimer.start(exit_time - %ExitTimer.time_left)
	else:
		var time_left_in_sixteenths: int = clamp(round(remap(%ExitDecayTimer.time_left, 0.0, 1.0, 0.0, 16.0)), 0, 16)
		display_return_icon(time_left_in_sixteenths)

	if !%LeftTimer.is_stopped():
		var percent_elapsed = (arrow_time - %LeftTimer.time_left) / arrow_time
		var time_elapsed_in_sixths: int = clamp(round(remap(percent_elapsed, 0.0, 1.0, 0.0, 6.0)), 0, 6)
		display_arrow_icon("left", time_elapsed_in_sixths)
		%LeftDecayTimer.start(arrow_time - %LeftTimer.time_left)
	else:
		var time_left_in_sixths: int = clamp(round(remap(%LeftDecayTimer.time_left, 0.0, 1.0, 0.0, 6.0)), 0, 6)
		display_arrow_icon("left", time_left_in_sixths)

	if !%RightTimer.is_stopped():
		var percent_elapsed = (arrow_time - %RightTimer.time_left) / arrow_time
		var time_elapsed_in_sixths: int = clamp(round(remap(percent_elapsed, 0.0, 1.0, 0.0, 6.0)), 0, 6)
		display_arrow_icon("right", time_elapsed_in_sixths)
		%RightDecayTimer.start(arrow_time - %LeftTimer.time_left)
	else:
		var time_left_in_sixths: int = clamp(round(remap(%RightDecayTimer.time_left, 0.0, 1.0, 0.0, 6.0)), 0, 6)
		display_arrow_icon("right", time_left_in_sixths)


func _input(event):
	if event.is_action_pressed("gun_left"):
		%LeftTimer.start(arrow_time)
	if event.is_action_released("gun_left"):
		%LeftTimer.stop()
	if event.is_action_pressed("gun_right"):
		%RightTimer.start(arrow_time)
	if event.is_action_released("gun_right"):
		%RightTimer.stop()

	if event.is_action_pressed("ui_cancel"):
		%ExitTimer.start(exit_time)
	if event.is_action_released("ui_cancel"):
		%ExitTimer.stop()


func exit():
	%ExitTimer.stop()
	%ExitDecayTimer.stop()
	if world.has_node("MenuLayer/PauseMenu"):
		world.get_node("MenuLayer/PauseMenu").visible = true
		world.get_node("MenuLayer/PauseMenu").do_focus()
	if world.has_node("MenuLayer/TitleScreen"):
		world.get_node("MenuLayer/TitleScreen").visible = true
		world.get_node("MenuLayer/TitleScreen").do_focus()
	queue_free()



### HELPERS ###

func display_return_icon(frame = 0):
	var return_icon = AtlasTexture.new()
	return_icon.atlas = RETURN_ICON
	return_icon.region = Rect2i(frame * 16, 0, 16, 16)
	%Settings.return_node.icon = return_icon
	%KeyConfig.return_node.icon = return_icon
	%ControllerConfig.return_node.icon = return_icon

func display_arrow_icon(arrow = "both", frame = 0):
	var arrow_icon = AtlasTexture.new()
	arrow_icon.region = Rect2i(frame * 16, 0, 16, 16)
	match arrow:
		"left", "both":
			arrow_icon.atlas = LEFT_ARROW
			%LeftArrow.texture = arrow_icon
		"right", "both":
			arrow_icon.atlas = RIGHT_ARROW
			%RightArrow.texture = arrow_icon



### SIGNALS ###

func change_tab(arrow = "left"):
	match arrow:
		"left":
			if tabs.current_tab == 0:
				tabs.current_tab = 2
			else:
				tabs.current_tab -= 1
		"right":
			if tabs.current_tab == 2:
				tabs.current_tab = 0
			else:
				tabs.current_tab += 1

func _on_TabContainer_tab_changed(tab):
	%LeftTimer.stop()
	%LeftDecayTimer.stop()
	%RightTimer.stop()
	%RightDecayTimer.stop()
	await get_tree().process_frame
	match tab:
		0: %Settings.do_focus()
		1: %KeyConfig.do_focus()
		2: %ControllerConfig.do_focus()

func _resolution_scale_changed(_resolution_scale):
	size = get_tree().get_root().size / vs.menu_resolution_scale
