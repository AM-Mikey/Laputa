extends Enemy

export var dir = Vector2.LEFT
var safe_distance = 100


var setup_complete = false

export var swoop_height = 3
export var swoop_distance = 5

onready var levels = get_tree().get_nodes_in_group("Levels")
#onready var cl = get_parent().get_parent().get_node("CameraLimiter")

func _ready():
	disabled = true
	#visible = false
	protected = true
	
	if not setup_complete:
		make_path()

	hp = 3
	damage_on_contact = 4
	speed = Vector2(200, 200)
	acceleration = 25
	
	level = 3

	
	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
	if dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")
		


func _physics_process(_delta):
	if setup_complete and not disabled:
		get_parent().offset += speed.x/100
		if get_parent().unit_offset == 1: #finished path
			protected = false
	

func on_cue():
	visible = true
	disabled = false
	print("cued swooper")
	

func make_path():
	var path = Path2D.new()
	var curve = Curve2D.new()
	var path_follow = PathFollow2D.new()
	var swooper = load("res://src/Actor/Enemy/Swooper.tscn").instance()
	
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(0, swoop_height * 16))
	curve.add_point(Vector2(dir.x * swoop_distance * 16, 0), Vector2(0, swoop_height * 16), Vector2.ZERO)
	
	path.curve = curve
	path.position = position
	path.name = "SwooperPath"
	get_parent().call_deferred("add_child", path)
	path_follow.rotate = false
	path_follow.loop = false
	path.add_child(path_follow)
	swooper.setup_complete = true
	swooper.dir = dir
	swooper.id = id
	path_follow.add_child(swooper)
	
	queue_free()
