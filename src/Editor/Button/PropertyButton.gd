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
		"bool", Variant.Type.TYPE_BOOL:
			$HBox/HBox/Bool.visible = true
			$HBox/HBox/Bool.button_pressed = property_value
		"color", Variant.Type.TYPE_COLOR:
			$HBox/HBox/Color.visible = true
			$HBox/HBox/Color.color = property_value
		"enum":
			$HBox/HBox/Enum.visible = true
			for i in enum_items:
				$HBox/HBox/Enum.add_item(i)
			$HBox/HBox/Enum.select(property_value)
		"int", Variant.Type.TYPE_INT:
			$HBox/HBox/String.visible = true
			if property_value != null: #"if property_value" doesn't trigger for value = 0
				$HBox/HBox/String.text = String("%.f" % int(property_value))
		"float", Variant.Type.TYPE_FLOAT:
			$HBox/HBox/String.visible = true
			if property_value != null:
				$HBox/HBox/String.text = str(property_value)
			
		"load":
			$HBox/HBox/Load.visible = true
			if property_value != null:
				$HBox/HBox/Load.text = str(property_value)
			
		"string", Variant.Type.TYPE_STRING:
			$HBox/HBox/String.visible = true
			if property_value != null:
				$HBox/HBox/String.text = String(property_value)
				
		"vector2", Variant.Type.TYPE_VECTOR2:
			$HBox/HBox/Vector2X.visible = true
			$HBox/HBox/Vector2Y.visible = true
			if property_value != null:
				$HBox/HBox/Vector2X.text = str(property_value.x)
				$HBox/HBox/Vector2Y.text = str(property_value.y)
				
		_:
			$HBox/HBox/String.visible = true
			if property_value != null:
				$HBox/HBox/String.text = str(property_value)

func align_enum_menu():
	#var menu = $Enum.get_popup()
	
	pass



### SIGNALS

func on_pressed():
	#print("button_pressed")
	emit_signal("property_selected", property_name)

func _on_String_text_entered(new_text):
	$HBox/HBox/String.release_focus()
	am.play("ui_accept")
	property_value = new_text
	emit_signal("property_changed", property_name, property_value)

func on_bool_toggled(button_pressed):
	#am.play("ui_accept")
	property_value = button_pressed
	emit_signal("property_changed", property_name, property_value)

func on_color_changed():
	property_value = $HBox/HBox/Color.color
	emit_signal("property_changed", property_name, property_value)

func on_enum_selected(index):
	#am.play("ui_accept")
	property_value = index
	emit_signal("property_changed", property_name, property_value)

func on_vector2x_entered(new_text):
	#am.play("ui_accept")
	property_value.x = float(new_text)
	emit_signal("property_changed", property_name, property_value)
func on_vector2y_entered(new_text):
	#am.play("ui_accept")
	property_value.y = float(new_text)
	emit_signal("property_changed", property_name, property_value)
