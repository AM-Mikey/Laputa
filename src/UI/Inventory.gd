extends Control

func _process(delta):
	if Input.is_action_just_pressed("pause") and get_tree().paused == false:
		get_tree().paused = true
		print("game paused")
		visible = true
	elif Input.is_action_just_pressed("pause") and get_tree().paused == true:
		get_tree().paused = false
		print("game unpaused")
		visible = false
		
