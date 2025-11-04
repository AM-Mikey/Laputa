extends Node2D

const END = preload("res://src/Utility/Rope/RopeEnd.tscn")
const PART = preload("res://src/Utility/Rope/RopePart.tscn")

#export var segment_count = 8
@export var softness = 0.01
@export var bias = 0.1

var start_pos = Vector2.ZERO
var end_pos = Vector2.ZERO
var segment_length = 6
var segments = []

# Called when the node enters the scene tree for the first time.
func _ready():
	start_pos = $StartPos.position
	end_pos = $EndPos.position

	var rope_angle = (end_pos - start_pos).angle() - PI/2

	var start = END.instantiate()
	start.position = start_pos
	add_child(start)
	segments.append(start)

	var segment_count = round(start_pos.distance_to(end_pos) / segment_length)
	for i in segment_count:
		var part = PART.instantiate()
		add_child(part)
		segments.append(part)


	var end = END.instantiate()
	end.position = end_pos
	add_child(end)
	segments.append(end)


	for s in segments:
		var id = segments.find(s)
		s.rotation = rope_angle

		var joint = s.get_node("Joint3D")
		joint.softness = softness
		joint.bias = bias

		if s == start:
			pass
		elif s == end:
			#pass
			segments[id-1].get_node("Joint3D").node_b = s.get_path()
		else:
			connect_part(s, segments[id-1].get_node("Joint3D"))





func connect_part(part, joint):
	part.global_position = joint.global_position
	#part.rotation = angle
	joint.node_b = part.get_path()


func _physics_process(delta):
	draw_rope()


func draw_rope():
	var points: PackedVector2Array
	for s in segments:
		points.append(s.position)

	$Line2D.points = points
