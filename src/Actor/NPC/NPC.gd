extends Actor
class_name NPC, "res://assets/Icon/NPCIcon.png"

export var has_face = false
export var voiced = true

var move_direction = Vector2.ZERO

var has_player_near = false
var talking = false
var active_player = null

var progress_disabled = false
var dialog_step: int = 1
var branch: String = ""

var displayname: String
var face: String
var expression: int
var text: String = "ERROR: NO DIALOG"
var justify

onready var npc_path = get_path()

onready var db = get_tree().get_root().get_node("World").get_node("UILayer/DialogBox")

signal display_text(npc_path, displayname, face, expression, text, justify, voiced)
signal speed_text()
signal stop_text()

signal show_branch(branch)
signal show_topic()



export (String, FILE, "*.json") var dialog_json: String


func _ready():
	if has_face == true:
		justify =  "Face"
	else:
		justify =  "NoFace"
		
	connect("display_text", db, "_on_display_text")
	connect("speed_text", db, "_on_speed_text")
	connect("stop_text", db, "_on_stop_text")
	
	connect("show_branch", db, "_on_show_branch")
	connect("show_topic", db, "_on_show_topic")

#movement stuff\
func _physics_process(delta):
	get_move_direction()
	_velocity = get_move_velocity(_velocity, move_direction, speed)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)

func get_move_direction() -> Vector2:
	return Vector2.ZERO

func get_move_velocity(
		linear_velocity: Vector2,
		move_direction: Vector2,
		speed: Vector2
		) -> Vector2:
	
	var out: = linear_velocity
	out.x = speed.x * move_direction.x
	out.y += gravity * get_physics_process_delta_time()
	if move_direction.y < 0:
		out.y = speed.y * move_direction.y
	return out

#sprite stuff
func animate():
	pass


#dialog stuff
func _on_PlayerDetector_body_entered(body):
	has_player_near = true
	active_player = body

func _on_ExitDetector_body_exited(body):
	has_player_near = false
	emit_signal("stop_text")
	if talking == true:
		talking = false


func progress_dialog(dialog):
	if progress_disabled == false:
		print("progressing dialog")
		
		
		var dialog_step_string = String(branch + "%02d" % dialog_step)
		print("dialog step id: ", dialog_step_string)
		if dialog.has(dialog_step_string): #if the next step is found
			text = dialog[dialog_step_string].text
			
			if dialog[dialog_step_string].has("displayname"):
				displayname = dialog[dialog_step_string].displayname
				
			if dialog[dialog_step_string].has("face"):
				face = dialog[dialog_step_string].face
				
			if dialog[dialog_step_string].has("expression"):
				expression = int(dialog[dialog_step_string].expression)
				
			if dialog[dialog_step_string].has("flags"):
				var flags = dialog[dialog_step_string]["flags"]
				
				if flags.has("add_topic"):
					add_topic(dialog[dialog_step_string]["flags"].add_topic)
					
				if flags.has("branch"):
					progress_disabled = true
					emit_signal("show_branch", flags.branch)
				
				if flags.has("merge"):
					branch = ""
					dialog_step = flags.merge - 1
					
				if flags.has("topic"):
					progress_disabled = true
					emit_signal("show_topic")
		
			emit_signal("display_text", npc_path, displayname, face, expression, text, justify, voiced)
			dialog_step +=1
		else: #if next step is not found
			print("next dialog step not found")
			end_dialog()

func end_dialog():
	pass

func load_dialog(dialog_json) -> Dictionary: #loads json and converts it into a dictionary
	var file = File.new()

	file.open(dialog_json, file.READ)
	var text = file.get_as_text()
	var dialog = JSON.parse(text).result
	return dialog


func add_topic(topic):
	active_player.topic_array.append(topic)
