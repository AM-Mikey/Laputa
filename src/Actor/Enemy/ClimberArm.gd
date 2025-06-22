extends Enemy

var index: int

func setup():
	hp = 2
	reward = 1
	damage_on_contact = 1
	$Label.visible = get_parent().get_parent().debug

func do_death_routine():
	var climber = get_parent().get_parent()
	
	if climber.state == "fall": #dont bother when about to chase
		return
	
	if index == climber.pivot_index:
		climber.change_state("fall")
	
	if climber.get_node("Arms").get_child_count() == 1: #we are the last child
		climber.change_state("chase")
