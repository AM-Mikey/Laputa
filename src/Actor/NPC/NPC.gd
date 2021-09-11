extends Actor
class_name NPC, "res://assets/Icon/NPCIcon.png"

const DB = preload("res://src/Dialog/DialogBox.tscn")

export var has_face = false
export var voiced = true

var move_dir= Vector2.ZERO
var target_pos = null

var has_player_near = false
var talking = false
var active_player = null

export var id: String

export (String, FILE, "*.json") var dialog_json: String
export var conversation: String
var dialog_step: int = 1
var branch: String = ""

var db 




func _ready():
	add_to_group("NPCs")


#getting where the camera's bounds are is a matter of getting the camera/player position, 
#applying the offset, and then checking the viewport size




#movement stuff
func _physics_process(delta):
	if talking and active_player.disabled == false: #if db freed the player
		talking = false
	

#	if target_pos != null:
#		if move_dir == Vector2.ZERO:
#			get_move_dir()
#		move_to_target_x()
		
	velocity = calculate_movevelocity(velocity, move_dir, speed)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)


func get_move_dir():
	move_dir.x = sign(target_pos.x - global_position.x)

func calculate_movevelocity(linearvelocity: Vector2,move_dir: Vector2,speed: Vector2) -> Vector2:
	var out: = linearvelocity
	
	#THIS CODE IS PRIMATIVE COMPARED TO PLAYER AND BOSS
	#if you need an npc with proper momementum and friction do something else
	
	out.x = speed.x * move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y
	return out

#sprite stuff
func animate():
	pass


#dialog stuff
func _on_PlayerDetector_body_entered(body):
	has_player_near = true
	active_player = body
	
func _on_PlayerDetector_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and dialog_json != "" and conversation != "":
		start_dialog()
		


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
	if id != null:
		print(id + " arrived at target position")
	move_dir = Vector2.ZERO
	target_pos = null
	
	if talking:
		db.busy = false
		db.dialog_loop()

func start_dialog():
	if talking == false:
		talking = true
		active_player.disabled = true
		active_player.invincible = true
		yield(get_tree().create_timer(.0001), "timeout")
		
		db = DB.instance()
		get_tree().get_root().get_node("World/UILayer").add_child(db)
	
		db.start_printing(dialog_json, conversation)  #new dialog start function
		print("starting conversation")
