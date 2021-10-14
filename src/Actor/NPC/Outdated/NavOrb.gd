extends NPC

const TARGETVISUAL = preload("res://src/Utility/TargetVisual.tscn")
const NAVIGATIONLINE = preload("res://src/Utility/NavigationLine.tscn")

var nav_final_point


var nav_path

var nav_point
var nav_point_index = 0

var no_jump_time = 0.5

onready var navigation = get_parent().get_parent().get_node("Tiles").get_node("Navigation2D")

func _ready():
	speed = Vector2(75, 75)



func _physics_process(_delta):
	if not is_on_floor():
		move_dir.y = 0
		
	if nav_point != null:
		move_to_nav_point()
		
		if nav_point != null and velocity.x == 0 and $NavTimer.time_left == 0:
			jump()
			
		elif nav_point != null and abs(global_position.x - nav_point.x) < 32: #less than 32 px horizontally from target
			if global_position.y - nav_point.y > 16: #more than 16px above us
				jump()

func jump():
	move_dir.y = -1
	
func get_next_nav_point():
	nav_point_index += 1
	if nav_point_index + 1 > nav_path.size():
		print("arrived at final nav point")
		move_dir = Vector2.ZERO
		return
	nav_point = nav_path[nav_point_index]
	
	for t in get_tree().get_nodes_in_group("TargetVisuals"):
		t.free()
	var target_visual = TARGETVISUAL.instance()
	target_visual.global_position = nav_point
	get_tree().get_root().get_node("World/Front").add_child(target_visual)
	
	###timer stuff
	$NavTimer.start(no_jump_time)
	


func move_to_nav_point():
	if abs(global_position.x - nav_point.x) < 8: #if less than 16px from point, stop
		arrive_at_nav_target()
	
	elif global_position.x > nav_point.x:
		move_dir = Vector2.LEFT

	elif global_position.x < nav_point.x:
		move_dir = Vector2.RIGHT

func arrive_at_nav_target():
	print("arrived at next nav point")
	move_dir = Vector2.ZERO
	nav_point = null
	get_next_nav_point()


func _input(event):
	if event.is_action_pressed("set_target"):
		#clear old targets
		for n in get_tree().get_nodes_in_group("NavigationLines"):
			n.free()
		
		
		nav_final_point = get_global_mouse_position()
		print("set nav target to: ", nav_final_point)
		
		#new targets

		
		
		var new_path = navigation.get_simple_path(global_position, nav_final_point)
		
		var navigation_line = NAVIGATIONLINE.instance()
		#navigation_line.global_position = global_position
		get_tree().get_root().get_node("World/Front").add_child(navigation_line)
		
		
		nav_path = new_path
		nav_point_index = 0
		get_next_nav_point()
		
