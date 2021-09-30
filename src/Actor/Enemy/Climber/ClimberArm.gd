extends Enemy

var part_type = "arm"
var arm_angle = 0

func _ready():
	hp = 2
	damage_on_contact = 1
	level = 1
