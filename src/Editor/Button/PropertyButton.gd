extends MarginContainer

signal property_selected(property_name)
signal property_changed(property_name, property_value)

var property_name: String
var property_value
var property_type
var enum_items := []
var disabled = false


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
			$HBox/HBox/Int.visible = true
			if property_value != null: #"if property_value" doesn't trigger for value = 0
				$HBox/HBox/Int.text = "%d" % int(property_value)
		"float", Variant.Type.TYPE_FLOAT:
			$HBox/HBox/Float.visible = true
			if property_value != null:
				$HBox/HBox/Float.text = "%.*f" % [get_decimal_digits(snapped(float(property_value), 0.001)), float(property_value)]
			
		"load":
			$HBox/HBox/Load.visible = true
			if property_value != null:
				$HBox/HBox/Load.text = str(property_value)
			
		"string", Variant.Type.TYPE_STRING:
			$HBox/HBox/String.visible = true
			if property_value != null:
				$HBox/HBox/String.text = String(property_value)
				
		"vector2", Variant.Type.TYPE_VECTOR2: #unused as we split this
			$HBox/HBox/Vector2X.visible = true
			$HBox/HBox/Vector2Y.visible = true
			if property_value != null:
				$HBox/HBox/Vector2X.text = "%.*f" % [get_decimal_digits(snapped(float(property_value.x), 0.001)), float(property_value.x)]
				$HBox/HBox/Vector2Y.text = "%.*f" % [get_decimal_digits(snapped(float(property_value.y), 0.001)), float(property_value.y)]
		_:
			$HBox/HBox/String.visible = true
			if property_value != null:
				$HBox/HBox/String.text = str(property_value)

func align_enum_menu():
	#var menu = $Enum.get_popup()
	pass

func get_decimal_digits(number) -> int: #Search Labs (Google) spat this out wholesale and it fucking works, funniest shit i've read
	var number_string = str(number)
	var decimal_index = number_string.find(".")
	if decimal_index != -1:
		return len(number_string) - decimal_index - 1
	else:
		return 0

### SIGNALS

func on_pressed():
	#print("button_pressed")
	emit_signal("property_selected", property_name)

func on_bool_toggled(button_pressed):
	if property_value != button_pressed and !disabled:
		property_value = button_pressed
		emit_signal("property_changed", property_name, property_value)
func on_color_changed():
	if property_value != $HBox/HBox/Color.color and !disabled:
		property_value = $HBox/HBox/Color.color
		emit_signal("property_changed", property_name, property_value)
func on_enum_selected(index):
	property_value = index
	emit_signal("property_changed", property_name, property_value)

func _on_string_complete(_value = 0):
	if property_value != $HBox/HBox/String.text and !disabled:
	#$HBox/HBox/String.release_focus()
		property_value = $HBox/HBox/String.text
		emit_signal("property_changed", property_name, property_value)
func _on_int_complete(_value = 0):
	if property_value != int($HBox/HBox/Int.text) and !disabled:
		property_value = int($HBox/HBox/Int.text)
		emit_signal("property_changed", property_name, property_value)
func _on_float_complete(_value = 0):
	if compare_floats(property_value, float($HBox/HBox/Float.text)) and !disabled:
		property_value = float($HBox/HBox/Float.text)
		emit_signal("property_changed", property_name, property_value)

func _on_vector2x_complete(_value = 0):
	if compare_floats(property_value.x, float($HBox/HBox/Vector2X.text)) and !disabled:
		property_value.x = float($HBox/HBox/Vector2X.text)
		emit_signal("property_changed", property_name, property_value)
func _on_vector2y_complete(_value = 0):
	if compare_floats(property_value.y, float($HBox/HBox/Vector2Y.text)) and !disabled:
		property_value.y = float($HBox/HBox/Vector2Y.text)
		emit_signal("property_changed", property_name, property_value)

func compare_floats(float1, float2) -> bool:
	if abs(float1 - float2) > 0.001: #because we round to this much
		return true
	else:
		return false
