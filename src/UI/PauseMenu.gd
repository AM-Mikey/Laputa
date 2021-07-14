extends Control

const OPTIONS = preload("res://src/UI/Settings.tscn")

onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()

func _process(delta):
	if Input.is_action_just_pressed("pause") and get_tree().paused == false:
		if get_parent().has_node("TitleScreen"):
			if get_parent().get_node("TitleScreen").visible:
				return
		
		get_tree().paused = true
		print("game paused")
		visible = true
	elif Input.is_action_just_pressed("pause") and get_tree().paused == true:
		get_tree().paused = false
		print("game unpaused")
		visible = false
		


func _on_Options_pressed():
	var options = OPTIONS.instance()
	add_child(options)


func _on_Return_pressed():
	get_tree().paused = false
	print("game unpaused")
	visible = false


func _on_Quit_pressed():
	get_tree().quit()

func _on_viewport_size_changed():
	$MarginContainer.rect_size = get_tree().get_root().size / world.resolution_scale
