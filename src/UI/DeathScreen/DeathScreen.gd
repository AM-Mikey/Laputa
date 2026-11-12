extends MarginContainer

const TITLE = preload("res://src/UI//Title/Title.tscn")

var _last_ticks := Time.get_ticks_usec()

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	do_focus()
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	if !SaveSystem.has_save:
		$VBox/HBox/Continue.visible = false


func do_focus():
	$VBox/HBox/Continue.grab_focus()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_delta := (now - _last_ticks) / 1_000_000.0
	_last_ticks = now
	$AnimationPlayer.advance(real_delta)

### SIGNALS ###

func _on_Continue_pressed():
	Engine.time_scale = 1.0
	visible = false
	w.get_node("DeathCamera").queue_free()
	w.get_node("DeathTransition").queue_free()
	SaveSystem.read_player_data_from_save()
	SaveSystem.read_level_data_from_save(w.current_level)
	SaveSystem.read_dialog_data_from_save(w.current_level)
	SaveSystem.copy_level_and_dialog_data_from_save_to_temp()
	SaveSystem.read_mission_data_from_save()
	queue_free()

func _on_DebugReload_pressed():
	visible = false
	w.get_node("DeathCamera").queue_free()
	w.get_node("DeathTransition").queue_free()
	DebugHotkeys.reload_level()
	queue_free()

func _on_Quit_pressed():
	Engine.time_scale = 1.0
	visible = false
	w.get_node("DeathCamera").queue_free()
	w.get_node("DeathTransition").queue_free()
	w.get_node("UILayer").add_child(TITLE.instantiate())
	#TODO: instead, return to a demo screen/level preview

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / resolution_scale)
