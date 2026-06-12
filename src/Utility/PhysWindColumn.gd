extends Node2D

const WIND_FAN = preload("res://src/Effect/WindFan.tscn")

var affected_entities := []

var wind_dir : Vector2
var speed : float #4 is about equal with gravity
var column_rect : Rect2 #in global
#var disable_gravity_on_horizontal := true

func _ready():
	$BodyDetector/CollisionShape2D.shape.size = column_rect.size
	$BodyDetector/CollisionShape2D.global_position = column_rect.position + (column_rect.size / 2.0)
	$ColorRect.size = column_rect.size
	$ColorRect.global_position = column_rect.position
	var wind_fan = WIND_FAN.instantiate()
	wind_fan.direction = wind_dir
	wind_fan.global_position = global_position
	wind_fan.tile_distance = (max(column_rect.size.x, column_rect.size.y) / 16.0)
	get_tree().get_root().get_node("World").middle.add_child(wind_fan)


func _physics_process(_delta: float):
	for a in affected_entities:
		if a.is_on_floor() && (wind_dir == Vector2.DOWN || (wind_dir == Vector2.UP && speed <= 4.0)):
			return
		a.velocity += wind_dir * speed


func _on_BodyDetector_body_entered(body: Node2D):
	if body.get_collision_layer_value(1): #player
		affected_entities.append(body.get_parent())
	elif body.get_collision_layer_value(2) || body.get_collision_layer_value(11): #enemy or pickup
		affected_entities.append(body)
	elif body.get_collision_layer_value(7) || body.get_collision_layer_value(14): #bullet or enemybull
		affected_entities.append(body)


func _on_BodyDetector_body_exited(body: Node2D):
	if body.get_collision_layer_value(1): #player
		affected_entities.erase(body.get_parent())
	elif body.get_collision_layer_value(2) || body.get_collision_layer_value(11): #enemy or pickup
		affected_entities.erase(body)
	elif body.get_collision_layer_value(7) || body.get_collision_layer_value(14): #bullet or enemybull
		if body.is_wind_affected:
			affected_entities.erase(body)
