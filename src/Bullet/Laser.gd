extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var duration = 0.0
var length = 0.0



func _ready():
	rotation_degrees = get_rot(direction)
	setup_vis_notifier()

func _physics_process(_delta):
	if disabled: return
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")

### HELPERS ###

func update_length(): 
	var col_shape = $CollisionDetector/CollisionShape2D.shape
	col_shape.size.x += length
	$CollisionDetector/CollisionShape2D.shape = col_shape
	$CollisionDetector/CollisionShape2D.position.x -= length /2
	
	$ColorRect.offset_left -= length
	$End.position.x -= length

### SIGNALS ###

func _on_CollisionDetector_body_exited(body):
	pass # Replace with function body.


func _on_Timer_timeout(): #starts on gun script
	queue_free()
	#do_fizzle("range")
