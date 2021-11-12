extends Enemy


export var amplitude: float = 2
export var frequency: float = 3
#export var period: float = .9

var time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(12, 120)
	gravity = 200
	
	level = 2

func _physics_process(delta):
	if not dead and not disabled:
		time += delta * frequency
		position.y += cos(time) * amplitude
		
	
		
		#move_and_slide(velocity)
