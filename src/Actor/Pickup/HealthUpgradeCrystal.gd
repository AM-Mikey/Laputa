extends Actor

var value: int
var dir := Vector2.DOWN
var prop_owner: Node
var sine_amplitude := 3.0
var sine_speed := 3.0
var time := 0.0

func _ready():
	gravity = 100
	home = global_position

func _physics_process(delta):
	time += delta
	var sine_offset = sin(time * sine_speed) * sine_amplitude
	global_position.y = home.y + sine_offset
	if !$AnimationPlayer.is_playing():
		if sine_offset < -2.5:
			$AnimationPlayer.play("Shine")

func exit():
	prop_owner.spent = true
	queue_free()
