extends Bullet

var start_velocity 
@onready var ap = $AnimationPlayer

func _ready():
	is_enemy_bullet = true
	ap.play("RotateLeft")
	
	velocity = get_initial_velocity()
	start_velocity = max((abs(velocity.x) + abs(velocity.y) / 2.0), 0.1) #used to calculate animation slowdown
	setup_vis_notifier()



func _physics_process(delta):
	if disabled: return
	velocity.y += gravity * delta
	move_and_slide()
	
	var current_velocity = abs(velocity.x) + abs(velocity.y) /2 #used to calculate animation slowdown
	ap.speed_scale = current_velocity / start_velocity
	if ap.speed_scale < .1:
		ap.stop()



### HELPERS ###

func get_initial_velocity() -> Vector2:
	var out = Vector2(\
	speed * direction.x,\
	speed * direction.y)
	return out

