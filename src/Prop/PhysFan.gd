extends Prop

const ICON = preload("res://assets/Prop/PhysFanIcon.png")
const PHYS_WIND_COLUMN = preload("res://src/Utility/PhysWindColumn.tscn")


var wind_dir : Vector2
@export var speed := 20.0 #4 is about equal with gravity
@export var toggled := true

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
	else:
		$AnimationPlayer.speed_scale = 1.0
		$AnimationPlayer.play("Off")

	w.emit_signal("finished_spawn_entities_step") #NOTE telling it we're done with setup early feels like cheating but this should work
	await get_tree().physics_frame
	await get_tree().physics_frame
	var phys_wind_column = PHYS_WIND_COLUMN.instantiate()
	phys_wind_column.wind_dir = wind_dir
	phys_wind_column.speed = speed
	phys_wind_column.column_rect = get_column_rect()
	phys_wind_column.global_position = global_position
	w.current_level.add_child(phys_wind_column) #TODO: maybe put this on a custom misc layer?


func activate(): #TODO: add buttons for this, shootable, standable, interactable
	toggled = !toggled
	if toggled:
		$AnimationPlayer.speed_scale = speed / 5.0 #TODO: doesnt yet have a way to play a continuous sfx, make vol scalable to speed
		$AnimationPlayer.play("On")
	else:
		$AnimationPlayer.speed_scale = 1.0
		$AnimationPlayer.play("Off")

### HELPERS ###

func get_column_rect() -> Rect2:
	var start_point: Vector2
	var end_point: Vector2
	match wind_dir:
		Vector2.LEFT:
			start_point = Vector2(0, 8)
		Vector2.RIGHT:
			start_point = Vector2(16, 8)
		Vector2.UP:
			start_point = Vector2(8, 0)
		Vector2.DOWN:
			start_point = Vector2(8, 16)

	$WorldCast.position = start_point
	if $WorldCast.is_colliding():
		end_point = to_local($WorldCast.get_collision_point())
	else:
		print("PhysFan didn't find a collision point, using PhysFan/WorldCast's length")
		end_point = $WorldCast.position + $WorldCast.target_position.rotated($WorldCast.rotation)

	var half_thickness := 8.0
	var min_corner := start_point.min(end_point) - Vector2(half_thickness, half_thickness)
	var max_corner := start_point.max(end_point) + Vector2(half_thickness, half_thickness)
	return Rect2(min_corner, max_corner - min_corner)
