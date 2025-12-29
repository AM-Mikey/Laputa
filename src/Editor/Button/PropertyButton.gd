extends MarginContainer

signal property_selected(property_name)
signal property_changed(property_name, property_value)

var property_name: String
var property_value
var property_type
var enum_items := []
var disabled = false #TODO: when is this used?

var enabled_controls = []
var is_mouse_entered = false

@onready var button = %Button
@onready var button_bool = %Bool
@onready var button_color = %Color
@onready var button_enum = %Enum
@onready var button_int = %Int
@onready var button_float = %Float
@onready var button_load = %Load
@onready var button_string = %String
@onready var button_multiline = %Multiline
@onready var button_vector2X = %Vector2x
@onready var button_vector2Y = %Vector2y

func _input(event: InputEvent):
	if event.is_action_pressed("editor_lmb") and !is_mouse_entered:
		for i in enabled_controls:
			if i.has_focus():
				i.release_focus()

func _ready():
	button.text = property_name
	align_enum_menu()

	match property_type:
		"bool", Variant.Type.TYPE_BOOL:
			enabled_controls.append(button_bool)
			button_bool.button_pressed = property_value
		"color", Variant.Type.TYPE_COLOR:
			enabled_controls.append(button_color)
			button_color.color = property_value
		"enum":
			enabled_controls.append(button_enum)
			for i in enum_items:
				button_enum.add_item(i)
			button_enum.select(property_value)

		"int", Variant.Type.TYPE_INT:
			enabled_controls.append(button_int)
			if property_value != null: #"if property_value" doesn't trigger for value = 0
				button_int.text = "%d" % int(property_value)
		"float", Variant.Type.TYPE_FLOAT:
			enabled_controls.append(button_float)
			if property_value != null:
				button_float.text = "%.*f" % [get_decimal_digits(snapped(float(property_value), 0.001)), float(property_value)]
		"load":
			enabled_controls.append(button_load)
			if property_value != null:
				button_load.text = str(property_value)
		"string", Variant.Type.TYPE_STRING:
			enabled_controls.append(button_string)
			if property_value != null:
				button_string.text = String(property_value)
		"multiline":
			enabled_controls.append(button_multiline)
			custom_minimum_size.y = 128
			if property_value != null:
				button_multiline.text = String(property_value)

		"vector2", Variant.Type.TYPE_VECTOR2: #unused as we split this
			enabled_controls.append(button_vector2X)
			enabled_controls.append(button_vector2Y)
			if property_value != null:
				button_vector2X.text = "%.*f" % [get_decimal_digits(snapped(float(property_value.x), 0.001)), float(property_value.x)]
				button_vector2Y.text = "%.*f" % [get_decimal_digits(snapped(float(property_value.y), 0.001)), float(property_value.y)]
		_:
			enabled_controls.append(button_string)
			if property_value != null:
				button_string.text = str(property_value)

	for i in enabled_controls:
		i.visible = true
		i.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
		i.connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func align_enum_menu(): ##TODO:why?
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

func _on_mouse_entered():
	is_mouse_entered = true
func _on_mouse_exited():
	is_mouse_entered = false

func on_pressed():
	#print("button_pressed")
	emit_signal("property_selected", property_name)

func on_bool_toggled(button_pressed):
	if property_value != button_pressed and !disabled:
		property_value = button_pressed
		emit_signal("property_changed", property_name, property_value)
func on_color_changed():
	if property_value != button_color.color and !disabled:
		property_value = button_color.color
		emit_signal("property_changed", property_name, property_value)
func on_enum_selected(index):
	property_value = index
	emit_signal("property_changed", property_name, property_value)

func _on_string_complete(_value = 0):
	if property_value != button_string.text and !disabled:
	#$HBox/HBox/String.release_focus()
		property_value = button_string.text
		emit_signal("property_changed", property_name, property_value)
func _on_multiline_complete(_value = 0):
	if property_value != button_multiline.text and !disabled:
		property_value = button_multiline.text
		emit_signal("property_changed", property_name, property_value)

func _on_int_complete(_value = 0):
	if property_value != int(button_int.text) and !disabled:
		property_value = int(button_int.text)
		emit_signal("property_changed", property_name, property_value)
func _on_float_complete(_value = 0):
	if compare_floats(property_value, float(button_float.text)) and !disabled:
		property_value = float(button_float.text)
		emit_signal("property_changed", property_name, property_value)

func _on_vector2x_complete(_value = 0):
	if compare_floats(property_value.x, float(button_vector2X.text)) and !disabled:
		property_value.x = float(button_vector2X.text)
		emit_signal("property_changed", property_name, property_value)
func _on_vector2y_complete(_value = 0):
	if compare_floats(property_value.y, float(button_vector2Y.text)) and !disabled:
		property_value.y = float(button_vector2Y.text)
		emit_signal("property_changed", property_name, property_value)

func compare_floats(float1, float2) -> bool:
	if abs(float1 - float2) > 0.001: #because we round to this much
		return true
	else:
		return false
