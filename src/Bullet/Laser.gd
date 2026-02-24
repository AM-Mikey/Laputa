extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var duration = 0.0
var length = 0.0



func _ready() -> void:
	rotation_degrees = get_rot(direction)
	super._ready()

func _physics_process(delta: float) -> void:
	if disabled: return
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")

	super._physics_process(delta)

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
