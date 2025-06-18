extends Enemy

var part_type = "body"

func _ready():
	hp = 4
	damage_on_contact = 2
	reward = 3

func _process(_delta):
	if get_parent() != null:
		$Sprite2D.rotation = 2 * PI - get_parent().rotation
