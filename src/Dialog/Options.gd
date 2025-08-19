extends Control

var options = ["Yes", "No", "Option Three", "Option Four", "Option Five", "Option Six"]
var ids = []

@export var up_down_cooldown_time = 0.2

var selected_option = 0
var is_displaying = false
var is_exiting = false
var exit_action = "continue"

func _ready():
	pass
	#display_options()
	
func display_options():
	print("displaying options")
	get_parent().get_node("AnimationPlayer").play("ResponseEnter")
	get_parent().get_node("Response").visible = true
	visible = true
	$Four.visible = false
	$Three.visible = false
	$Two.visible = false
	
	if options.size() > 4:
		$Up.visible = true
		$Down.visible = true
	else:
		$Up.visible = false
		$Down.visible = false
	if options.size() >= 4:
		$Four/First/Label.text = options[0]
		$Four/Second/Label.text = options[1]
		$Four/Third/Label.text = options[2]
		$Four/Forth/Label.text = options[3]
		$Four.visible = true
	elif options.size() == 3:
		$Three/First/Label.text = options[0]
		$Three/Second/Label.text = options[1]
		$Three/Third/Label.text = options[2]
		$Three.visible = true
	elif options.size() == 2:
		$Two/First/Label.text = options[0]
		$Two/Second/Label.text = options[1]
		$Two.visible = true
	else:
		printerr("ERROR: OPTION COUNT ==: ", options.size())


func _input(event):
	if event.is_action_pressed("ui_up"):
		$UpDownTimer.start(up_down_cooldown_time)
		option_up()
	if event.is_action_pressed("ui_down"):
		$UpDownTimer.start(up_down_cooldown_time)
		option_down()
	if event.is_action_pressed("ui_accept") and is_displaying and not is_exiting:
		hide_options()


func hide_options():
	is_exiting = true
	get_parent().do_delay = false
	#print("set_delay_false")
	await get_tree().create_timer(0.1).timeout #wait for text to finish printing without delay
	get_parent().dl = get_parent().get_node("NPC/DialogNPC")
	get_parent().dl.text = ""
	get_parent().flash_original_text = ""
	#print("cleared dl")
	get_parent().get_node("AnimationPlayer").play("ResponseExit")
	await get_parent().get_node("AnimationPlayer").animation_finished
	
	match exit_action:
		"continue":
			get_parent().progress_text(false)
		"options":
			get_parent().get_node("CommandHandler").on_select_branch(selected_option)
		"topics":
			get_parent().get_node("CommandHandler").on_select_branch(ids[selected_option])
	is_displaying = false
	is_exiting = false

### HELPER ###

func option_up():
	if options.size() >= 4:
		if selected_option == 0:
			selected_option = options.size() - 1
			$AnimationPlayer.play("FourFirstToForth")
			$Four/First/Label.text = options[selected_option - 3]
			$Four/Second/Label.text = options[selected_option - 2]
			$Four/Third/Label.text = options[selected_option - 1]
			$Four/Forth/Label.text = options[selected_option]
		else:
			selected_option -= 1
			var optionsminustwo = options.size() - 2
			var optionsminusthree = options.size() - 3
			match selected_option:
				optionsminustwo: $AnimationPlayer.play("FourForthToThird")
				optionsminusthree: $AnimationPlayer.play("FourThirdToSecond")
				_: 
					if selected_option == 0:
						$AnimationPlayer.play("FourSecondToFirst")
					else:
						$AnimationPlayer.play("FourScrollUp")
	
	elif options.size() == 3:
		if selected_option == 0:
			selected_option = 2
			$AnimationPlayer.play("ThreeFirstToThird")
		else:
			selected_option -= 1
			match selected_option:
				1: $AnimationPlayer.play("ThreeThirdToSecond")
				0: $AnimationPlayer.play("ThreeSecondToFirst")
	
	elif options.size() == 2:
		if selected_option == 0:
			selected_option = 1
			$AnimationPlayer.play("TwoFirstToSecond")
		elif selected_option == 1:
			selected_option = 0
			$AnimationPlayer.play("TwoSecondToFirst")




func option_down():
	if options.size() >= 4:
		if selected_option == options.size() - 1:
			selected_option = 0
			$AnimationPlayer.play("FourForthToFirst")
			$Four/First/Label.text = options[0]
			$Four/Second/Label.text = options[1]
			$Four/Third/Label.text = options[2]
			$Four/Forth/Label.text = options[3]
		else:
			selected_option += 1
			match selected_option:
				1: $AnimationPlayer.play("FourFirstToSecond")
				2: $AnimationPlayer.play("FourSecondToThird")
				_: 
					if selected_option == options.size() - 1:
						$AnimationPlayer.play("FourThirdToForth")
					else:
						$AnimationPlayer.play("FourScrollDown")
	
	elif options.size() == 3:
		if selected_option == 2:
			selected_option = 0
			$AnimationPlayer.play("ThreeThirdToFirst")
		else:
			selected_option += 1
			match selected_option:
				1: $AnimationPlayer.play("ThreeFirstToSecond")
				2: $AnimationPlayer.play("ThreeSecondToThird")
	
	elif options.size() == 2:
		if selected_option == 0:
			selected_option = 1
			$AnimationPlayer.play("TwoFirstToSecond")
		elif selected_option == 1:
			selected_option = 0
			$AnimationPlayer.play("TwoSecondToFirst")



func down_label_swap():
	#3 (1234) -> 4 (2345)
	$Four/First/Label.text = options[selected_option - 2]
	$Four/Second/Label.text = options[selected_option - 1]
	$Four/Third/Label.text = options[selected_option]
	$Four/Forth/Label.text = options[selected_option + 1]

func up_label_swap():
	#4 (2345) -> 3 (1234)
	$Four/First/Label.text = options[selected_option - 1]
	$Four/Second/Label.text = options[selected_option]
	$Four/Third/Label.text = options[selected_option + 1]
	$Four/Forth/Label.text = options[selected_option + 2]

### SIGNALS ###

#func _on_AnimationPlayer_animation_finished(anim_name: StringName):
	#if Input.is_action_pressed("ui_up"):
		#$UpDownTimer.start(up_down_cooldown_time)
		#option_up()
	#if Input.is_action_pressed("ui_down"):
		#$UpDownTimer.start(up_down_cooldown_time)
		#option_down()


func _on_MainAnimationPlayer_animation_finished(anim_name: StringName):
	if anim_name == "ResponseEnter":
		is_displaying = true


func _on_UpDownTimer_timeout():
	if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_down"):
		return
	elif Input.is_action_pressed("ui_up"):
		$UpDownTimer.start(up_down_cooldown_time)
		option_up()
	elif Input.is_action_pressed("ui_down"):
		$UpDownTimer.start(up_down_cooldown_time)
		option_down()
