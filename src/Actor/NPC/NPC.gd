extends Actor
class_name NPC, "res://assets/Icon/NPCIcon.png"

const DB = preload("res://src/Dialog/DialogBox.tscn")

export var has_face = false
export var voiced = true

var move_dir= Vector2.ZERO
var target_pos = null

var talking = false
var active_pc = null

export var id: String

export (String, FILE, "*.json") var dialog_json: String
export var conversation: String
var dialog_step: int = 1
var branch: String = ""



var camera_forgiveness = 16

#onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node_or_null("World/Juniper")

func _ready():
	add_to_group("NPCs")







#movement stuff


func _physics_process(_delta):

	if talking:
		if not check_within_camera():
			print("npc left screen, ending dialog")
			talking = false
			var db = world.get_node("UILayer/DialogBox")
			db.stop_printing()



	velocity = calculate_movevelocity(velocity, move_dir, speed)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)






#dialog stuff
func _on_PlayerDetector_body_entered(body):
	active_pc = body
	
func _on_PlayerDetector_body_exited(_body):
	active_pc = null

func _input(event):
	if event.is_action_pressed("inspect") and active_pc != null and dialog_json != "" and conversation != "":
		start_dialog()


func start_dialog():
	if not talking:
		talking = true
		orient()
		yield(get_tree().create_timer(.0001), "timeout") #why? #TODO
	
		if world.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
			world.get_node("UILayer/DialogBox").stop_printing()
			
		var dialog_box = DB.instance()
		dialog_box.connect("dialog_finished", self, "on_dialog_finished")
		get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
		dialog_box.start_printing(dialog_json, conversation)
		print("starting conversation")


func orient():
	active_pc.face_dir.x = sign(position.x - active_pc.position.x)

func on_dialog_finished():
	talking = false

############################################################### TODO: clean up this old stuff \/

func check_within_camera() -> bool:
	if pc:
		pc = get_tree().get_root().get_node_or_null("World/Juniper")
	var cam_pos = pc.get_node("PlayerCamera").get_camera_screen_center() #gets ONLY the player camera center with offset
	if cam_pos:
		return is_within_camera(cam_pos)
	else:
		return false


func is_within_camera(cam_pos):
	var cam_size = OS.get_window_size() / world.resolution_scale  #gets active viewport, may have to devide by resolution scale
	if global_position.x > cam_pos.x - (cam_size.x /2 + camera_forgiveness) and global_position.x < cam_pos.x + (cam_size.x /2 + camera_forgiveness):
		if global_position.y > cam_pos.y - (cam_size.y /2 + camera_forgiveness) and global_position.y < cam_pos.y + (cam_size.y /2 + camera_forgiveness):
			return true
		else: return false
	else: return false

func get_move_dir():
	move_dir.x = sign(target_pos.x - global_position.x)

func calculate_movevelocity(linearvelocity: Vector2, scoped_move_dir: Vector2, speed: Vector2) -> Vector2:
	var out: = linearvelocity
	
	#THIS CODE IS PRIMATIVE COMPARED TO PLAYER AND BOSS
	#if you need an npc with proper momementum and friction do something else
	
	out.x = speed.x * scoped_move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if scoped_move_dir.y < 0:
		out.y = speed.y * scoped_move_dir.y
	return out

#sprite stuff
func animate():
	pass



#movement stuff
func move_to_target_x():
	if id != null:
		print(id + " moving to target_pos: ", target_pos)
	if move_dir == Vector2.LEFT:
		if global_position.x <= target_pos.x:
			arrive_at_target()
	if move_dir == Vector2.RIGHT:
		if global_position.x >= target_pos.x:
			arrive_at_target()
			
func arrive_at_target():
	var db = world.get_node("UILayer/DialogBox")
	
	if id != null:
		print(id + " arrived at target position")
	move_dir = Vector2.ZERO
	target_pos = null
	
	if talking:
		db.busy = false
		db.dialog_loop()
