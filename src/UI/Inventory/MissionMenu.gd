extends Control

const MISSION_BOOKMARK := preload("res://src/UI/Inventory/MissionBookmark.tscn")
const MISSIONS_PER_PAGE := 4
const SIBLING_SHIFT_AMOUNT := 20.0

# Indices for MissionSystem.main_mission_stage
const STAGE_TITLE := 0
const STAGE_DESCRIPTION := 3
const ARROW_ENABLED_REGION_X := 9

# Main mission
@onready var main_mission_title: RichTextLabel = %MainMissionTitle
@onready var main_mission_body: RichTextLabel = %MainMissionBody

# Pagination controls
@onready var left_arrow: TextureButton = %LeftArrow
@onready var right_arrow: TextureButton = %RightArrow
@onready var fraction: RichTextLabel = %Fraction

# Side missions
@onready var side_mission_container: VBoxContainer = %SideMissionContainer
@onready var side_mission_body: RichTextLabel = %SideMissionBody
@onready var mission_completed_text: TextureRect = %MissionCompletedText
@onready var stamp_imprint: TextureRect = %StampImprint
@onready var stamp_animator: AnimationPlayer = %StampAnimator

@onready var missions: MissionSystem = ms

var all_side_missions: Array[SideMission] = []
var current_page := 0

var selected_mission: SideMission = null
var selected_bookmark: MissionBookmark = null

var _is_playing_resolution := false


func _ready() -> void:
	for arrow in [left_arrow, right_arrow]:
		arrow.texture_normal = arrow.texture_normal.duplicate()

	left_arrow.pressed.connect(prev_page)
	right_arrow.pressed.connect(next_page)

	enter()


func enter() -> void:
	_update_main_mission()
	if missions.resolved_side_mission_queue.is_empty():
		update_side_missions(missions.get_partitioned_side_missions())
	else:
		_play_resolution_animations()


func _update_main_mission() -> void:
	main_mission_title.text = missions.main_mission_stage[STAGE_TITLE]
	main_mission_body.text = missions.main_mission_stage[STAGE_DESCRIPTION]


func get_page_count() -> int:
	return maxi(1, ceili(float(all_side_missions.size()) / MISSIONS_PER_PAGE))


func next_page() -> void:
	set_page(current_page + 1)


func prev_page() -> void:
	set_page(current_page - 1)


func set_page(page: int) -> void:
	if _is_playing_resolution:
		return
	var clamped := clampi(page, 0, get_page_count() - 1)
	if clamped == current_page:
		return
	current_page = clamped
	_show_page()


func _page_start() -> int:
	return current_page * MISSIONS_PER_PAGE


func _update_page_ui() -> void:
	var total := get_page_count()
	fraction.text = "%d/%d" % [current_page + 1, total]
	_set_arrow_enabled(left_arrow, current_page > 0)
	_set_arrow_enabled(right_arrow, current_page < total - 1)


func _set_arrow_enabled(arrow: TextureButton, enabled: bool) -> void:
	arrow.disabled = not enabled
	var atlas := arrow.texture_normal as AtlasTexture
	if atlas:
		var region := atlas.region
		region.position.x = ARROW_ENABLED_REGION_X if enabled else 0
		atlas.region = region


func update_side_missions(side_missions: Array[SideMission]) -> void:
	all_side_missions = side_missions
	current_page = clampi(current_page, 0, get_page_count() - 1)
	_show_page()


func _show_page() -> void:
	for child in side_mission_container.get_children():
		side_mission_container.remove_child(child)
		child.queue_free()
	selected_bookmark = null

	var start := _page_start()
	var end := mini(start + MISSIONS_PER_PAGE, all_side_missions.size())
	for i in range(start, end):
		_create_bookmark(all_side_missions[i])

	_update_page_ui()


func _create_bookmark(mission: SideMission) -> MissionBookmark:
	var bookmark: MissionBookmark = MISSION_BOOKMARK.instantiate()
	side_mission_container.add_child(bookmark)

	var pending := missions.resolved_side_mission_queue.has(mission)
	bookmark.setup(mission, mission == selected_mission, pending)
	bookmark.mission_selected.connect(func(m: SideMission) -> void:
		_on_mission_selected(m, bookmark))

	if mission == selected_mission:
		selected_bookmark = bookmark
		bookmark.select()

	return bookmark


func _on_mission_selected(mission: SideMission, bookmark: MissionBookmark) -> void:
	if _is_playing_resolution:
		return
	_select(mission, bookmark)
	_show_selected_details(mission)


func _select(mission: SideMission, bookmark: MissionBookmark) -> void:
	if is_instance_valid(selected_bookmark) and selected_bookmark != bookmark \
			and selected_bookmark.is_inside_tree():
		selected_bookmark.deselect()

	selected_mission = mission
	selected_bookmark = bookmark
	if bookmark != null:
		bookmark.select()


## Shows the description and, for completed missions, the stamp imprint.
func _show_selected_details(mission: SideMission) -> void:
	side_mission_body.modulate.a = 1.0
	side_mission_body.text = mission.description

	var is_complete := mission.status == SideMission.Status.COMPLETE
	stamp_imprint.visible = is_complete
	mission_completed_text.visible = is_complete


func _play_resolution_animations() -> void:
	_is_playing_resolution = true
	_set_arrow_enabled(left_arrow, false)
	_set_arrow_enabled(right_arrow, false)

	current_page = 0
	all_side_missions = missions.get_partitioned_side_missions(missions.resolved_side_mission_queue)
	_show_page()
	await get_tree().process_frame

	stamp_animator.play("FORWARD")
	await stamp_animator.animation_finished

	var queue: Array = missions.resolved_side_mission_queue.duplicate()
	for i in queue.size():
		await _animate_single_resolution(queue[i], i == queue.size() - 1)

	missions.resolved_side_mission_queue.clear()
	stamp_animator.play("BACK")
	await stamp_animator.animation_finished

	_is_playing_resolution = false
	_reset_stamp_visuals()

	# Finally, jump to the page holding the selected mission, if it's still listed
	var final_missions := missions.get_partitioned_side_missions()
	var idx := final_missions.find(selected_mission)
	current_page = floori(float(idx) / MISSIONS_PER_PAGE) if idx >= 0 else 0
	update_side_missions(final_missions)
	if idx >= 0:
		_show_selected_details(selected_mission)


func _reset_stamp_visuals() -> void:
	mission_completed_text.visible = false
	stamp_imprint.visible = false
	mission_completed_text.modulate.a = 1.0
	stamp_imprint.modulate.a = 1.0


func _animate_single_resolution(mission: SideMission, is_last: bool) -> void:
	var bookmark := _find_bookmark_for(mission)
	_select(mission, bookmark)
	side_mission_body.modulate.a = 1.0
	side_mission_body.text = mission.description

	stamp_animator.play("STAMP")
	await stamp_animator.animation_finished

	if bookmark == null:
		all_side_missions.erase(mission)
		return

	# So, the bookmarks below will shift up while the current fades, that way we get a smooth transition
	# rather than snapping immediately using VBoxContainer's remove_child()
	var siblings_to_shift := _get_bookmarks_below(bookmark)

	await bookmark.start_complete_animation()
	for sibling in siblings_to_shift:
		sibling._offset(SIBLING_SHIFT_AMOUNT)
	await get_tree().create_timer(MissionBookmark.COMPLETE_FADE_DURATION).timeout

	side_mission_container.remove_child(bookmark)
	bookmark.queue_free()
	selected_bookmark = null
	all_side_missions.erase(mission)
	_refill_current_page_if_needed()

	if is_last:
		await get_tree().create_timer(MissionBookmark.APPEAR_FADE_DURATION).timeout
		return

	stamp_animator.play("FADE_SIDE_MISSION")
	await stamp_animator.animation_finished


func _refill_current_page_if_needed() -> void:
	var next_index := _page_start() + side_mission_container.get_child_count()
	if next_index >= all_side_missions.size():
		return
	_create_bookmark(all_side_missions[next_index]).appear_animation()

func _find_bookmark_for(mission: SideMission) -> MissionBookmark:
	for child in side_mission_container.get_children():
		if child.mission_data == mission:
			return child
	return null


func _get_bookmarks_below(bookmark: MissionBookmark) -> Array[MissionBookmark]:
	var below: Array[MissionBookmark] = []
	var found := false
	for child in side_mission_container.get_children():
		if found:
			below.append(child)
		elif child == bookmark:
			found = true
	return below
