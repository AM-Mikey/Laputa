extends Actor
class_name NPC, "res://assets/Icon/NPCIcon.png"

const DB = preload("res://src/Dialog/DialogBox.tscn")
const STATE_LABEL = preload("res://src/Utility/StateLabel.tscn")

var state: String
var cached_state: String
var talking = false
var dialog_step: int = 1
var branch: String = ""

var active_pc = null
var disabled = false
var move_dir = Vector2.LEFT
var target_pos = null

export var id: String
export (String, FILE, "*.json") var dialog_json: String
export var conversation: String
export var has_face = false
export var voiced = true


var camera_forgiveness = 16

onready var pc = get_tree().get_root().get_node_or_null("World/Juniper")

func _ready():
	add_to_group("NPCs")
	setup_states()
	change_state("walk")


func disable():
	disabled = true

func enable():
	disabled = false



func change_animation(animation: String, random_start = false):
	if not $AnimationPlayer.has_animation(animation):
		print("WARNING: animation: " + animation + " not found on npc with name: " + name)
	
	$AnimationPlayer.play(animation)
	var start_time = 0
	
	if random_start:
		rng.randomize()
		start_time = rng.randf_range(0, $AnimationPlayer.current_animation_length)
	
	$AnimationPlayer.seek(start_time, true)



### STATES ###

func setup_states():
	var timer = Timer.new()
	timer.one_shot = true
	timer.name = "StateTimer"
	add_child(timer)
	
	var label = STATE_LABEL.instance()
	label.text = state
	label.name = "StateLabel"
	add_child(label)
	
func do_state():
	var do_method = "do_" + state
	if has_method(do_method):
		call(do_method)
	#else: printerr("ERROR: Enemy: " + name + " is missing state method with name: " + do_method)

func change_state(new):
	if state:
		var exit_method = "exit_" + state
		if has_method(exit_method):
			call(exit_method)
	state = new
	$StateLabel.text = state
	var enter_method = "enter_" + state
	if has_method(enter_method):
		call(enter_method)


### STATE FUNCTIONS


func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	
	rng.randomize()
	change_animation("Walk")
	$StateTimer.start(rng.randf_range(1.0, 10.0))
	yield($StateTimer, "timeout")
	change_state("wait")


func do_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		change_state("wait")
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		change_state("wait")
	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
		velocity = get_velocity()
		velocity = move_and_slide(velocity, FLOOR_NORMAL)
	


func enter_wait():
	rng.randomize()
	change_animation("Idle", true)
	$StateTimer.start(rng.randf_range(1.0, 5.0))
	yield($StateTimer, "timeout")
	change_state("walk")


#func do_wait():
	

func _physics_process(_delta):
	if disabled:
		return

	$Sprite.flip_h = true if move_dir.x > 0 else false #set sprite to move_dir

	if state != "":
		do_state()

#	if talking: DEPRECIATED
#		if not check_within_camera():
#			print("npc left screen, ending dialog")
#			talking = false
#			var db = world.get_node("UILayer/DialogBox")
#			db.stop_printing()

func enter_talk():
	orient()
	#yield(get_tree().create_timer(.0001), "timeout") #why? #TODO
	if world.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
		world.get_node("UILayer/DialogBox").exit()
		
	var dialog_box = DB.instance()
	dialog_box.connect("dialog_finished", self, "on_dialog_finished")
	get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
	
	var justification = "face"
	if not has_face:
		justification = "no_face"
	
	dialog_box.start_printing(dialog_json, conversation, justification)
	print("starting conversation")

func do_talk():
	pass

func exit_talk():
	pass

func _input(event):
	if event.is_action_pressed("inspect") and active_pc and dialog_json != "" and conversation != "":
		cached_state = state
		change_state("talk")


func orient():
	active_pc.look_dir.x = sign(position.x - active_pc.position.x)

func on_dialog_finished():
	change_state(cached_state)
	#talking = false

############################################################### TODO: clean up this old stuff \/



func get_move_dir():
	move_dir.x = sign(target_pos.x - global_position.x)


func get_velocity(do_gravity = true) -> Vector2:
	var out: = velocity
	out.x = speed.x * move_dir.x
	if do_gravity:
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = speed.y * move_dir.y
	else:
		out.y = speed.y * move_dir.y
	return out



#movement stuff
func move_to_target_x():
	if id:
		print(id + " moving to target_pos: ", target_pos)
	if move_dir == Vector2.LEFT:
		if global_position.x <= target_pos.x:
			arrive_at_target()
	if move_dir == Vector2.RIGHT:
		if global_position.x >= target_pos.x:
			arrive_at_target()
			
func arrive_at_target():
	var db = world.get_node("UILayer/DialogBox")
	
	if id:
		print(id + " arrived at target position")
	move_dir = Vector2.ZERO
	target_pos = null
	
	if talking:
		db.busy = false
		db.dialog_loop()


### HELPERS

#func check_within_camera() -> bool:
#	if pc:
#		pc = get_tree().get_root().get_node_or_null("World/Juniper")
#	var cam_pos = pc.get_node("PlayerCamera").get_camera_screen_center() #gets ONLY the player camera center with offset
#	if cam_pos:
#		return is_within_camera(cam_pos)
#	else:
#		return false


#func is_within_camera(cam_pos):
#	var cam_size = OS.get_window_size() / world.resolution_scale  #gets active viewport, may have to devide by resolution scale
#	if global_position.x > cam_pos.x - (cam_size.x /2 + camera_forgiveness) and global_position.x < cam_pos.x + (cam_size.x /2 + camera_forgiveness):
#		if global_position.y > cam_pos.y - (cam_size.y /2 + camera_forgiveness) and global_position.y < cam_pos.y + (cam_size.y /2 + camera_forgiveness):
#			return true
#		else: return false
#	else: return false


### SIGNALS

func _on_PlayerDetector_body_entered(body):
	active_pc = body
	
func _on_PlayerDetector_body_exited(_body):
	active_pc = null
