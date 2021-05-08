extends Control

const OPTIONS = preload("res://src/UI/Settings.tscn")

func _process(delta):
	if Input.is_action_just_pressed("pause") and get_tree().paused == false:
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
