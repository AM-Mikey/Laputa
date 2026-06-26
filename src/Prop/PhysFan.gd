extends Prop

const ICON = preload("res://assets/Prop/PhysFanIcon.png")
const PHYS_WIND_COLUMN = preload("res://src/Utility/PhysWindColumn.tscn")


var wind_dir : Vector2
var phys_wind_column : Node
@export var speed := 20.0 #4 is about equal with gravity
@export var toggled := true
var fan_start_sfx_player: Node
var fan_loop_sfx_player: Node
var fan_vis_wind_up_duration := 3.33
var fan_vis_wind_down_duration := 6.66

func setup(): #Reminder: no function called can use await
	wind_dir = $WindVector.direction.snapped(Vector2(1, 1)) #remove VUVector imprecision

	match wind_dir:
		Vector2.LEFT:
			$Sprite2D.frame_coords.y = 0
			$WorldCast.rotation_degrees = 0
		Vector2.RIGHT:
			$Sprite2D.frame_coords.y = 1
			$WorldCast.rotation_degrees = 180
		Vector2.UP:
			$Sprite2D.frame_coords.y = 2
			$WorldCast.rotation_degrees = 90
		Vector2.DOWN:
			$Sprite2D.frame_coords.y = 3
			$WorldCast.rotation_degrees = -90

	if toggled:
		$AnimationPlayer.speed_scale = speed / 5.0
		$AnimationPlayer.play("On")
		_do_sfx_loop()
	else:
		$AnimationPlayer.speed_scale = 1.0
		$AnimationPlayer.play("Off")

	w.emit_signal("finished_spawn_entities_step") #NOTE telling it we're done with setup early feels like cheating but this should work
	await get_tree().physics_frame
	await get_tree().physics_frame
	if toggled:
		create_phys_wind_column()



### HELPERS ###

func create_phys_wind_column():
	phys_wind_column = PHYS_WIND_COLUMN.instantiate()
	phys_wind_column.wind_dir = wind_dir
	phys_wind_column.speed = speed
	phys_wind_column.column_rect = get_column_rect()
	phys_wind_column.global_position = global_position + get_column_pos()
	w.current_level.add_child(phys_wind_column) #TODO: maybe put this on a custom misc layer?

func get_column_pos() -> Vector2:
	match wind_dir:
		Vector2.LEFT:
			return Vector2(0, 8)
		Vector2.RIGHT:
			return Vector2(16, 8)
		Vector2.UP:
			return Vector2(8, 0)
		Vector2.DOWN:
			return Vector2(8, 16)
		_:
			printerr("ERROR: PhysFan wind_dir isn't ortagonal!")
			return Vector2.ZERO

func get_column_rect() -> Rect2:
	var column_pos = get_column_pos()
	var start_point = global_position + column_pos + Vector2(0, -8).rotated(wind_dir.angle())
	var end_point

	$WorldCast.position = column_pos
	if $WorldCast.is_colliding():
		end_point = $WorldCast.get_collision_point() + Vector2(0, 8).rotated(wind_dir.angle())
	else:
		print("PhysFan didn't find a collision point, using PhysFan/WorldCast's length")
		end_point = $WorldCast.global_position + $WorldCast.target_position.rotated($WorldCast.rotation) + Vector2(0, 8).rotated(wind_dir.angle())

	var rect_pos = Vector2(min(start_point.x, end_point.x), min(start_point.y, end_point.y))
	var rect_size = Vector2(abs(start_point.x - end_point.x), abs(start_point.y - end_point.y))
	return Rect2(rect_pos, rect_size)



### SFX ###

func _do_sfx_start():
	if fan_start_sfx_player:
		am.clear_player_by_node(fan_start_sfx_player)
		fan_start_sfx_player = null
		return
	fan_start_sfx_player = am.play("fan_start", self, null, 0.8, 0.0)
	await get_tree().create_timer(am.get_sfx_duration("fan_start")).timeout
	#await get_tree().create_timer(6.98).timeout #stupid but no gap/pop in audio like this. exact time of fanstart.ogg
	#await fan_start_sfx_player.finished #0.0006 second gap from the last one finishing to this audio starting. that sucks #in the case of _do_sfx_end() starting during this await, it never finishes this await. this is desired behavior
	if fan_start_sfx_player:
		_do_sfx_loop()


func _do_sfx_loop():
	if fan_start_sfx_player:
		am.clear_player_by_node(fan_start_sfx_player)
		fan_start_sfx_player = null
	fan_loop_sfx_player = am.play("fan_loop", self, null, 0.8, 0.0)

func _do_sfx_end():
	if fan_loop_sfx_player:
		am.clear_player_by_node(fan_loop_sfx_player)
		fan_loop_sfx_player = null
	if fan_start_sfx_player:
		am.clear_player_by_node(fan_start_sfx_player)
		fan_start_sfx_player = null
	am.play("fan_end", self, null, 0.8, 0.0)



func _physics_process(_delta):
	var max_speed_scale = speed / 5.0
	if !$VisWindUp.is_stopped():
		$AnimationPlayer.speed_scale = max_speed_scale - (max_speed_scale * ($VisWindUp.time_left / fan_vis_wind_up_duration))
	elif !$VisWindDown.is_stopped():
		$AnimationPlayer.speed_scale = ($VisWindDown.time_left / fan_vis_wind_down_duration) * max_speed_scale
		if $AnimationPlayer.speed_scale <= 0.01:
			$AnimationPlayer.stop()
	else:
		$AnimationPlayer.speed_scale = max_speed_scale #TODO: doesnt yet have a way to play a continuous sfx, make vol scalable to speed

### SIGNALS ###

func on_switch_toggled(switch_toggled):
	toggled = switch_toggled
	$AnimationPlayer.play("On")
	if toggled:
		$VisWindUp.start(fan_vis_wind_up_duration)
		create_phys_wind_column()
		_do_sfx_start()
	else:
		$VisWindDown.start(fan_vis_wind_down_duration)
		phys_wind_column.effect.stop()
		phys_wind_column.queue_free()
		_do_sfx_end()


func on_switch_timer_start():
	toggled = true
	$AnimationPlayer.play("On")
	$VisWindUp.start(fan_vis_wind_up_duration)
	create_phys_wind_column()
	_do_sfx_start()


func on_switch_timer_timeout():
	toggled = false
	$VisWindDown.start(fan_vis_wind_down_duration)
	phys_wind_column.effect.stop()
	phys_wind_column.queue_free()
	_do_sfx_end()
