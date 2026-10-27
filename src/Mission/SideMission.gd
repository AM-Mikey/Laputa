@icon("res://assets/Icon/SideMission.png")
extends Resource
class_name SideMission

# Move this to another file
enum Status { IN_PROGRESS, COMPLETE, FAILED }

@export var display_name: String = "Null Side Mission"
@export_multiline() var description: String
@export var stages: Array[Array] #[name, trigger_type, trigger_value]
@export var current_stage: String


@export var status: Status = Status.IN_PROGRESS
