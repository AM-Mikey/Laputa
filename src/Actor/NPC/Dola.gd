extends NPC

var already_talked = false

#onready var dialog = load_dialog(dialog_json)


func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true:
		active_player.disabled = true
		active_player.invincible = true
		if talking == false:
			talking = true
			
			#if already_talked == false:
			#conversation = dialog["intro"]
			#else:
			#conversation = dialog["default"]
				
			yield(get_tree().create_timer(.0001), "timeout")
			progress_dialog(conversation)

func end_dialog():
	print("ended dialog")
	branch = "" #may be undesired to reset the convo
	#already_talked = true
	
	talking = false
	dialog_step = 1
	emit_signal("stop_text")
	
	active_player.disabled = false
	active_player.invincible = false


