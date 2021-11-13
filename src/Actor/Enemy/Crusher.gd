extends Enemy


export var amplitude: float = 16
export var frequency: float = 4

var middle_height: int
var time: float = 0

func _ready():
	$AnimationPlayer.play("Float")
	middle_height = global_position.y

func _physics_process(delta):
	if not dead and not disabled:
		time += delta * frequency
		position.y = middle_height + cos(time) * amplitude

