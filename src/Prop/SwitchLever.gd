extends Prop

signal switch_toggled(toggled)
signal switch_activated
signal switch_timer_start
signal switch_timer_timeout


const ICON = preload("res://assets/Prop/SwitchLeverIcon.png")
enum SwitchType {TOGGLE, IMPULSE, TIMER}

@export var connected_entity_id : String
@export var toggled = false
@export var switch_type := SwitchType.TOGGLE
@export var timer_duration := 1.0

var connected_entities := []
var switch_siblings := [] #NOTE this only works for toggle switches right now


func setup(): #Reminder: no function called can use await before finishing entities step
	w.emit_signal("finished_spawn_entities_step") #NOTE we say this is finished immediately so we can be the LAST loaded props, this is why we then need to await four times
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	for e in get_tree().get_nodes_in_group("Entities"):
		if e.is_in_group("EditorEntities"):
			return
		if "id" in e:
			if e.id.nocasecmp_to(connected_entity_id) == 0:
				connected_entities.append(e)
	for c in connected_entities:
		match switch_type:
			SwitchType.TOGGLE:
				connect("switch_toggled", Callable(c, "on_switch_toggled"))
			SwitchType.IMPULSE:
				connect("switch_activated", Callable(c, "on_switch_activated"))
			SwitchType.TIMER:
				connect("switch_timer_start", Callable(c, "on_switch_timer_start"))
				connect("switch_timer_timeout", Callable(c, "on_switch_timer_timeout"))
	await get_tree().process_frame #to set connected entity
	switch_siblings = get_switch_siblings()
	for s in switch_siblings:
		if s.toggled != toggled:
			printerr("WARNING: SWITCH SIBLINGS DON'T AGREE ON 'toggled', forcing off")
			s.toggled = false
	if switch_type == SwitchType.TOGGLE:
		for c in connected_entities:
			c.toggled = toggled
		if toggled:
			$AnimationPlayer.play("PresetDown")
		else:
			$AnimationPlayer.play("PresetUp")

func get_switch_siblings() -> Array:
	var out = []
	for s in get_tree().get_nodes_in_group("Switches"):
		if s != self && s.connected_entity_id == connected_entity_id && connected_entity_id != null:
			if s.is_in_group("SwitchPlates"):
				printerr("ERROR: CANNOT USE MIXED PLATE + LEVER OR CRYSTAL AS SWITCH SIBLINGS")
			if switch_type == SwitchType.TOGGLE:
				out.append(s)
			else:
				printerr("ERROR, switch ", self, " and switch ", s, " have same connected_entity_id: ", connected_entity_id)
				breakpoint
	return out


func activate():
	ms.mission_progress_check(id)
	match switch_type:
		SwitchType.TOGGLE:
			toggled = !toggled
			#sibling code
			for s in switch_siblings:
				s.toggled = toggled
				if s.is_in_group("SwitchLevers"):
					if toggled: s.get_node("AnimationPlayer").play("Down")
					else: s.get_node("AnimationPlayer").play("Up")
				elif s.is_in_group("SwitchCrystals"):
					if toggled: s.get_node("AnimationPlayer").play("Hit")
					else: s.get_node("AnimationPlayer").play("Off")
			#self code
			if toggled: $AnimationPlayer.play("Down")
			else: $AnimationPlayer.play("Up")
			emit_signal("switch_toggled", toggled)

		SwitchType.IMPULSE:
			$AnimationPlayer.play("Pull")
			emit_signal("switch_activated")

		SwitchType.TIMER:
			if !toggled:
				toggled = true
				$AnimationPlayer.play("Down")
				emit_signal("switch_timer_start")
				$Timer.start(timer_duration)
				await $AnimationPlayer.animation_finished
				$AnimationPlayer.play("Timer")

func _do_click():
	am.play("switch_lever_down", null, null, 0.8, 0)
	oup.vibrate_impulse(0.4, 0.2)
func _do_release():
	am.play("switch_lever_up", null, null, 0.4, 0)
	oup.vibrate_impulse(0.2, 0.2)
func _do_tick():
	am.play("switch_timer", self, null, 1.0, 0)
	oup.vibrate_impulse_light(0.2, 0.1)

### SIGNALS ###

func _on_PlayerDetector_body_entered(body: Node2D):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body: Node2D):
	active_players.erase(body.get_parent())


func _on_Timer_timeout():
	toggled = false
	$AnimationPlayer.play("Up")
	emit_signal("switch_timer_timeout")
