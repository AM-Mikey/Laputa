extends MarginContainer

const FILE_PREVIEW = preload("res://src/UI/FileSelect/FilePreview.tscn")
const RETURN_ICON = preload("res://assets/UI/Options/IconReturn.png")


var exit_time := 0.4
var save_file_indices: Array[int]

@onready var w = get_tree().get_root().get_node("World")


func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	await load_files()
	%FilePreviews.get_child(0).grab_focus()


func load_files():
	save_file_indices = SaveSystem.get_save_file_indices()
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
	if event.is_action_released("ui_cancel") or event.is_action_released("pause"):
		%ExitTimer.stop()



### HELPERS ###

func display_return_icon(frame = 0):
	var return_icon = AtlasTexture.new()
	return_icon.atlas = RETURN_ICON
	return_icon.region = Rect2i(frame * 16, 0, 16, 16)
	%Return.icon = return_icon

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

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / vs.menu_resolution_scale)
