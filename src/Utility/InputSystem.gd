extends Node

var active_controller_index = 0
var controller_asleep = false

var buttonconfig := {
	holdjumping = false,
	buttons = {},
	}

			#STICK
var analogstick:Vector2 = Vector2(0,0)
var Xaxis_deadzone:float = 0.2 #general deadzone
var Yaxis_deadzone:float = 0.2 #general deadzone
var Xaxis_clampzone:float = 0.85 #everything after this input is turned into 1.0
var Y_axis_shoot_deadzone:float = 0.25

			#ETC
var can_act:= true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS #keep the buffer accurate while the tree is paused (menus, inventory)
	for action in BUFFERED_ACTIONS:
		buffer[action] = BufferedAction.new()
	Input.joy_connection_changed.connect(_on_joypad_connection_changed)

func rawstick() -> Vector2:
	var outputX:float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var outputY:float = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	return Vector2(outputX,outputY)

func stick_deadzone(stick:Vector2,deadzoneX:float=Xaxis_deadzone,deadzoneY:float=Yaxis_deadzone) -> Vector2:
	var result:Vector2 = stick
	if abs(result.x) < deadzoneX: result.x = 0.0
	if abs(result.y) < deadzoneY: result.y = 0.0
	return result

func stick_clamp_zone_X(stick:Vector2, clampX:float=Xaxis_clampzone) -> Vector2:
	var result:Vector2 = stick
	if abs(result.x) >= clampX:
		result.x = sign(result.x)
	return result


### BUFFER ###

# Raw stick/trigger travel (0-1) needed before an action counts as pressed.
# Uses raw strength, so the InputMap action deadzones do not stack on top of this.
var input_strength: float = 0.5
# Raw travel an action has to drop below before it counts as released.
# Lower than inputstrength so a stick resting near the threshold doesn't flicker (hysteresis).
var release_strength: float = 0.3
# Optional per-action thresholds, e.g. {"fire_automatic": {"press": 0.6, "release": 0.4}}
var strength_overrides: Dictionary = {}
var pressbuffer: int = 4
var releasebuffer: int = 1

const NEVER := 9000
const UNREAD := -1
const DISCARDED := -2

class BufferedAction:
	var held_frames := 0
	var frames_since_press := 9000
	var frames_since_release := 9000
	var press_read_frame := -1
	var release_read_frame := -1
	var pressed_while_can_act := false

#A button needs to be added to this to be bufferable
const BUFFERED_ACTIONS: Array[String] = [
	"look_up",
	"look_down",
	"move_left",
	"move_right",
	"jump",
	"fire_manual",
	"fire_automatic",
	"inspect",
	"inventory",
	"ui_up",
	"ui_down",
	"ui_left",
	"ui_right",
	]

var buffer: Dictionary = {} #action name -> BufferedAction
var _was_paused := false

func _on_joypad_connection_changed(_device: int, _connected: bool): #for if controller is connected during
	print("controllers changed")
	if Input.get_connected_joypads().size() == 0:
		active_controller_index = -1
	else:
		if active_controller_index in Input.get_connected_joypads():
			set_active_controller_index(active_controller_index)
		else:
			set_active_controller_index(Input.get_connected_joypads()[0]) #lowest number

func set_active_controller_index(index):
	active_controller_index = index
	set_input_map_index(active_controller_index)
	for j in Input.get_connected_joypads():
		if j == active_controller_index:
			oup.level_gradient = get_tree().get_root().get_node("World").current_level.controller_color_gradient
		else:
			oup.set_controller_light_color(j, oup.inactive_controller_color)

func set_input_map_index(index: int):
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
				event.device = index
				InputMap.action_add_event(action, event)


func _physics_process(_delta):
	analogstick = stick_clamp_zone_X(stick_deadzone(rawstick()))

	write_buffer()
	var paused := get_tree().paused
	if paused != _was_paused: #kill the press that paused/unpaused
		_was_paused = paused
		discard_presses()

func _input(event: InputEvent): #for sleep
	if event.device == active_controller_index && (event is InputEventJoypadButton || (event is InputEventJoypadMotion && event.axis in [4, 5])): #triggers
		if controller_asleep:
			controller_asleep = false
			oup.do_level_gradient = true
			oup.set_controller_light_color(active_controller_index, oup.active_controller_color)
	elif event is InputEventKey:
		if !controller_asleep:
			controller_asleep = true
			oup.do_level_gradient = false
			oup.set_controller_light_color(active_controller_index, oup.asleep_controller_color)


func _threshold(action: String, currently_held: bool) -> float:
	var o: Dictionary = strength_overrides.get(action, {})
	if currently_held:
		return o.get("release", release_strength)
	return o.get("press", input_strength)

#Tracks the state of every buffered action. ignores can_act so a button held through a can_act=false period doesn't register as a new press later.
func write_buffer():
	for action in buffer:
		var b: BufferedAction = buffer[action]
		b.frames_since_press = mini(b.frames_since_press + 1, NEVER)
		b.frames_since_release = mini(b.frames_since_release + 1, NEVER)
		var was_held := b.held_frames > 0
		var is_held := Input.get_action_raw_strength(action) >= _threshold(action, was_held)
		if is_held:
			if not was_held:
				b.frames_since_press = 0
				b.press_read_frame = UNREAD
				b.pressed_while_can_act = can_act
			b.held_frames += 1
		elif was_held:
			b.held_frames = 0
			b.frames_since_release = 0
			b.release_read_frame = UNREAD

func discard_presses():
	for action in buffer:
		buffer[action].press_read_frame = DISCARDED

func _get_buffered(button: String) -> BufferedAction:
	if not buffer.has(button):
		printerr("INPUT NOT FOUND IN BUFFER: ", button)
		return null
	return buffer[button]

#press/release can be read by any number of callers during the physics frame it is first read on, and not after.
#NOTE: CALL FROM _physics_process ONLY
func _read(read_frame: int) -> int:
	var frame := Engine.get_physics_frames()
	if read_frame == UNREAD or read_frame == frame:
		return frame
	return DISCARDED

func pressed(button: String, custombuffer: int = pressbuffer, bypass_can_act := false) -> bool: #buffered
	var b := _get_buffered(button)
	if b == null: return false
	if b.held_frames == 0 or b.frames_since_press > custombuffer: return false
	if not bypass_can_act and (not can_act or not b.pressed_while_can_act): return false #bypass for ui
	b.press_read_frame = _read(b.press_read_frame)
	return b.press_read_frame != DISCARDED

func just_pressed(button: String, bypass_can_act := false) -> bool: #not consumed
	var b := _get_buffered(button)
	if b == null: return false
	if not bypass_can_act and (not can_act or not b.pressed_while_can_act): return false
	return b.held_frames > 0 and b.frames_since_press == 0

func held(button: String, below: int = 900000000, above: int = 0, bypass_can_act := false) -> bool:
	var b := _get_buffered(button)
	if b == null: return false
	if not bypass_can_act and not can_act: return false
	return b.held_frames > above and b.held_frames <= below

func released(button: String, custombuffer: int = releasebuffer) -> bool: #Buffered + consumed
	var b := _get_buffered(button)
	if b == null: return false
	if b.held_frames > 0 or b.frames_since_release > custombuffer: return false
	b.release_read_frame = _read(b.release_read_frame)
	return b.release_read_frame != DISCARDED

func just_released(button: String) -> bool: #not consumed
	var b := _get_buffered(button)
	if b == null: return false
	return b.held_frames == 0 and b.frames_since_release == 0
