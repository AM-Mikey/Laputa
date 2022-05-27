extends MarginContainer

signal property_changed(property_name)

var property_name: String
var property_value
var property_type: int

func _ready():
	$HBox/Button.text = property_name

	match property_type:
		TYPE_BOOL:
			$HBox/Bool.visible = true
			$HBox/Bool.pressed = property_value
		TYPE_VECTOR2:
			$HBox/Vector2X.visible = true
			$HBox/Vector2Y.visible = true
			if property_value:
				$HBox/Vector2X.text = String(property_value.x)
				$HBox/Vector2Y.text = String(property_value.y)
		_:
			$HBox/String.visible = true
			if property_value:
				$HBox/String.text = String(property_value)

func on_text_entered(new_text):
	property_value = new_text
	emit_signal("property_changed", property_name, property_value)


func on_bool_toggled(button_pressed):
	property_value = button_pressed
	emit_signal("property_changed", property_name, property_value)


func on_vector2x_entered(new_text):
	property_value.x = float(new_text)
	emit_signal("property_changed", property_name, property_value)
func on_vector2y_entered(new_text):
	property_value.y = float(new_text)
	emit_signal("property_changed", property_name, property_value)
