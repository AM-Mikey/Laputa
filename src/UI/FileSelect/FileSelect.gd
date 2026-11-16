extends MarginContainer

const FILE_PREVIEW = preload("res://src/UI/FileSelect/FilePreview.tscn")
const RETURN_ICON = preload("res://assets/UI/Options/IconReturn.png")

enum Modes {LOAD, COPY, DELETE}
var mode = Modes.LOAD

var exit_time := 0.4
var save_file_indices: Array[int]
var pending_delete_index := -1


@onready var w = get_tree().get_root().get_node("World")


func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	$DeleteConfirmation.confirmed.connect(_on_delete_confirmed)
	$DeleteConfirmation.canceled.connect(_on_delete_canceled)
	await load_files()
	%FilePreviews.get_child(0).get_node("Button").grab_focus()


func load_files():
	save_file_indices = SaveSystem.get_save_file_indices()
	save_file_indices.sort()
	for i in save_file_indices:
		var file_preview = FILE_PREVIEW.instantiate()
		file_preview.save_file_path = "user://save_%d.dat" % i
		file_preview.slot_index = i
		file_preview.file_select = self
		%FilePreviews.add_child(file_preview)


func _physics_process(_delta):
	if !%ExitTimer.is_stopped():
		var percent_elapsed = (exit_time - %ExitTimer.time_left) / exit_time
		var time_elapsed_in_sixteenths: int = clamp(round(remap(percent_elapsed, 0.0, 1.0, 0.0, 16.0)), 0, 16)
		display_return_icon(time_elapsed_in_sixteenths)
		%ExitDecayTimer.start(exit_time - %ExitTimer.time_left)
	else:
		var time_left_in_sixteenths: int = clamp(round(remap(%ExitDecayTimer.time_left, 0.0, 1.0, 0.0, 16.0)), 0, 16)
		display_return_icon(time_left_in_sixteenths)


func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		%ExitTimer.start(exit_time)
		if mode != Modes.LOAD:
			mode = Modes.LOAD
			%FilePreviews.get_child(0).get_node("Button").grab_focus()

	if event.is_action_released("ui_cancel") or event.is_action_released("pause"):
		%ExitTimer.stop()



### HELPERS ###

func display_return_icon(frame = 0):
	var return_icon = AtlasTexture.new()
	return_icon.atlas = RETURN_ICON
	return_icon.region = Rect2i(frame * 16, 0, 16, 16)
	%Return.icon = return_icon

func reload_previews(focus_slot := -1):
	for c in %FilePreviews.get_children():
		%FilePreviews.remove_child(c)
		c.queue_free()
	load_files()
	if %FilePreviews.get_child_count() == 0:
		exit()
		return
	var to_focus = %FilePreviews.get_child_count(0)
	for c in %FilePreviews.get_children():
		if c.slot_index == focus_slot:
			to_focus = c

func prompt_delete(index: int):
	pending_delete_index = index
	$DeleteConfirmation.popup_centered()
	$DeleteConfirmation.get_cancel_button().grab_focus() #focus "no"

func exit():
	%ExitTimer.stop()
	%ExitDecayTimer.stop()
	if w.has_node("MenuLayer/PauseMenu"):
		w.get_node("MenuLayer/PauseMenu").visible = true
		w.get_node("MenuLayer/PauseMenu").do_focus()
	if w.has_node("MenuLayer/Title"):
		w.get_node("MenuLayer/Title").visible = true
		w.get_node("MenuLayer/Title").do_focus()
	queue_free()



### SIGNALS ###

func _on_Return_pressed():
	_process_exit()

func _process_exit():
	exit()


func _on_Copy_pressed():
	mode = Modes.COPY
	%FilePreviews.get_child(0).get_node("Button").grab_focus()

func _on_Delete_pressed():
	mode = Modes.DELETE
	%FilePreviews.get_child(0).get_node("Button").grab_focus()

func _on_delete_confirmed():
	SaveSystem.file_select_delete_save(pending_delete_index)
	pending_delete_index = -1
	mode = Modes.LOAD
	reload_previews()

func _on_delete_canceled():
	pending_delete_index = -1
	mode = Modes.LOAD
	%FilePreviews.get_child(0).get_node("Button").grab_focus()

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / vs.menu_resolution_scale)
