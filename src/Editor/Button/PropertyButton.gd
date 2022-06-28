extends MarginContainer

signal property_selected(property_name)
signal property_changed(property_name, property_value)

var property_name: String
var property_value
var property_type
var enum_items := []

func _ready():
	$HBox/Button.text = property_name
	
	align_enum_menu()

	match property_type:
		"bool", TYPE_BOOL:
			$HBox/Bool.visible = true
			$HBox/Bool.pressed = property_value
		"color", TYPE_COLOR:
			$HBox/Color.visible = true
			$HBox/Color.color = property_value
		"enum":
			$HBox/Enum.visible = true
			for i in enum_items:
				$HBox/Enum.add_item(i)
			$HBox/Enum.select(property_value)


		"int", TYPE_INT:
			$HBox/String.visible = true
			if property_value != null: #"if property_value" doesn't trigger for value = 0
				$HBox/String.text = String("%.f" % property_value)
		"float", TYPE_REAL:
			$HBox/String.visible = true
			if property_value != null:
				$HBox/String.text = String(property_value)
			
		"load":
			$HBox/Load.visible = true
			if property_value != null:
				$HBox/Load.text = String(property_value)
			
		"string", TYPE_STRING:
			$HBox/String.visible = true
			if property_value != null:
				$HBox/String.text = String(property_value)
				
		"vector2", TYPE_VECTOR2:
			$HBox/Vector2X.visible = true
			$HBox/Vector2Y.visible = true
			if property_value != null:
				$HBox/Vector2X.text = String(property_value.x)
				$HBox/Vector2Y.text = String(property_value.y)
				
		_:
			$HBox/String.visible = true
			if property_value != null:
				$HBox/String.text = String(property_value)

func align_enum_menu():
	#var menu = $Enum.get_popup()
	
	pass



### SIGNALS

func on_pressed():
	#print("button_pressed")
	emit_signal("property_selected", property_name)

#func on_text_entered(new_text):
#	property_value = new_text
#	emit_signal("property_changed", property_name, property_value)

func on_bool_toggled(button_pressed):
	property_value = button_pressed
	emit_signal("property_changed", property_name, property_value)

func on_color_changed():
	property_value = $HBox/Color.color
	emit_signal("property_changed", property_name, property_value)

func on_enum_selected(index):
	property_value = index
	emit_signal("property_changed", property_name, property_value)

func on_vector2x_entered(new_text):
	property_value.x = float(new_text)
	emit_signal("property_changed", property_name, property_value)
func on_vector2y_entered(new_text):
	property_value.y = float(new_text)
	emit_signal("property_changed", property_name, property_value)


func _on_String_text_changed(new_text):
	property_value = new_text
	emit_signal("property_changed", property_name, property_value)
