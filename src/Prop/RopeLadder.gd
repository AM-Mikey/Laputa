extends Prop

const LADDER = preload("res://src/Trigger/Ladder.tscn")
var ladder_trigger: Node
var length: int
var sprites := []
var sprite_to_animate

func setup():
	inspect_time = 0.1
	await get_tree().process_frame #needs for some reason
	setup_length()

func setup_length():
	if $Ground.is_colliding():
		length = $Ground.get_collision_point().y - $Ground.global_position.y
		sprites.append($Sprite2D)
		var sprite_count = int(floor(length / 16.0)) - 1
		for i in sprite_count:
			var duplicated_sprite = $Sprite2D.duplicate(0)
			add_child(duplicated_sprite)
			duplicated_sprite.global_position += Vector2(0, (i + 1) * 16.0)  # +1 so it doesn't overlap original
			duplicated_sprite.get_node("AnimationPlayer").root_node = duplicated_sprite.get_path()
			duplicated_sprite.frame = 0
			sprites.append(duplicated_sprite)

func _input(event):
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && inp.can_act && p.mm.current_state == p.mm.states["run"]:
				if spent:
					return
				#var previous_look_dir = p.look_dir
				#p.mm.change_state("inspect")
				#p.inspect_target = $CollisionShape2D
				activate()
				#await get_tree().create_timer(inspect_time, false, true).timeout
				#p.mm.change_state("run")
				#p.look_dir = previous_look_dir

func activate():
	am.play("rope_loose", self)
	spent = true
	ms.mission_progress_check(id)

	for s in sprites:
		if s == sprites.front():
			s.get_node("AnimationPlayer").play("Top")
		elif s == sprites.back():
			s.get_node("AnimationPlayer").play("Complete")
		else:
			s.get_node("AnimationPlayer").play("Unfurl")
		am.play("rope_land", self)
		await get_tree().create_timer(0.075, false, true).timeout
	setup_ladder_trigger()


func setup_ladder_trigger():
	ladder_trigger = LADDER.instantiate()
	ladder_trigger.id = id #might cause conflict but just change that later if need be
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16.0, length)
	ladder_trigger.get_node("CollisionShape2D").shape = shape
	ladder_trigger.get_node("CollisionShape2D").position = Vector2(8.0, length / 2.0)
	ladder_trigger.global_position = global_position + Vector2(0, 16)
	w.current_level.get_node("Triggers").add_child(ladder_trigger)

### SIGNALS ###

func _on_PlayerDetector_body_entered(body: Node2D):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body: Node2D):
	active_players.erase(body.get_parent())
