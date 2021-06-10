extends Actor
class_name NPC, "res://assets/Icon/NPCIcon.png"

export var has_face = false
export var voiced = true

var move_dir= Vector2.ZERO
var target_pos = null

var has_player_near = false
var talking = false
var active_player = null

var id

export (String, FILE, "*.json") var dialog_json: String
var conversation
var dialog_step: int = 1
var branch: String = ""


onready var db = get_tree().get_root().get_node("World").get_node("UILayer/DialogBox")





func _ready():
	add_to_group("NPCs")


#movement stuff\
func _physics_process(delta):
	if talking and active_player.disabled == false: #if db freed the player
		talking = false
	

	if target_pos != null:
		move_to_target_x()
		
	_velocity = calculate_move_velocity(_velocity, move_dir, speed)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)



func calculate_move_velocity(linear_velocity: Vector2,move_dir: Vector2,speed: Vector2) -> Vector2:
	var out: = linear_velocity
	
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
	if event.is_action_pressed("inspect") and has_player_near == true:
		start_dialog()
		


func move_to_target_x():
	if move_dir == Vector2.LEFT:
		if global_position.x <= target_pos.x:
			arrive_at_target()
	if move_dir == Vector2.RIGHT:
		if global_position.x >= target_pos.x:
			arrive_at_target()
			
func arrive_at_target():
	print(id + " arrived at target position")
	move_dir = Vector2.ZERO
	target_pos = null
	db.busy = false
	db.dialog_loop()

func start_dialog():
	if talking == false:
		talking = true
		active_player.disabled = true
		active_player.invincible = true
		yield(get_tree().create_timer(.0001), "timeout")
	
		db.start_printing(dialog_json, conversation)  #new dialog start function
