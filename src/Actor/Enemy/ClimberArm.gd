extends Enemy

var index: int

signal arm_die(arm)

func setup():
	hp = 2
	reward = 1
	damage_on_contact = 1
	$Label.visible = get_parent().get_parent().debug

func do_death_routine():
	arm_die.emit(self)
