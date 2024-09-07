extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var minimum_speed: float = 6
var bounciness = 1 #.6
var start_velocity
var touched_floor = false



@onready var w = get_tree().get_root().get_node("World")
@onready var pc = w.get_node("Juniper")



func _ready():
	$FizzleTimer.start(f_time)
	break_method = "cut"

	velocity = get_initial_velocity()
	start_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	


func _physics_process(delta):
	if not disabled:
		velocity.y += gravity * delta
		
		if velocity.x > 0:
			$AnimationPlayer.play("FlipLeft")
		else:
			$AnimationPlayer.play("FlipRight")
		
		var collision = move_and_collide(velocity * delta)
		if collision:
			if abs(velocity.y) > minimum_speed:
				velocity *= bounciness
				velocity = velocity.bounce(collision.get_normal())
				am.play("gun_star_bounce", self)
			else:
				velocity = Vector2.ZERO
	
	
	var avr_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$AnimationPlayer.speed_scale = avr_velocity / start_velocity
	if $AnimationPlayer.speed_scale < .1:
		$AnimationPlayer.stop()




func get_initial_velocity() -> Vector2:
	var out = velocity

	out.x = speed * direction.x
	out.y = speed * direction.y
	
	out.y -= 80 #give us some ups to start with

	return out



### SIGNALS ###

func _on_CollisionDetector_body_entered(body): #shadows
	if disabled:
		return
	if not body is TileMap:
		#enemy
		if body.get_collision_layer_value(2): 
			if not touched_floor:
				body.hit(damage, get_blood_dir(body))
			else:
				body.hit(int(damage/2), get_blood_dir(body))
			queue_free()

func _on_CollisionDetector_area_entered(_area): #shadows
	pass

func _on_FizzleTimer_timeout():
	do_fizzle("range")
