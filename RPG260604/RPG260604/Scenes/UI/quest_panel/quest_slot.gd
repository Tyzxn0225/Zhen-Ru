extends Button
class_name QuestSlot

signal on_quest_slot_clicked(slot_index: int)

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var tracked_frame: Panel = %TrackedFrame

var slot_index: int = -1
var 任务ID: String = ""


func set_quest(
	quest_id: String,
	title: String,
	description: String,
	is_tracked: bool,
	is_completed: bool
) -> void:
	任务ID = quest_id
	if quest_id.is_empty():
		clear_slot()
		return
	if title_label:
		title_label.text = title + ("  ✓" if is_completed else "")
	if desc_label:
		desc_label.text = description
	disabled = is_completed
	mouse_filter = MOUSE_FILTER_IGNORE if is_completed else MOUSE_FILTER_STOP
	modulate = Color(0.55, 0.55, 0.6, 1.0) if is_completed else Color.WHITE
	if tracked_frame:
		tracked_frame.visible = is_tracked and not is_completed
	show()


func clear_slot() -> void:
	任务ID = ""
	if title_label:
		title_label.text = ""
	if desc_label:
		desc_label.text = ""
	disabled = true
	mouse_filter = MOUSE_FILTER_IGNORE
	modulate = Color.WHITE
	if tracked_frame:
		tracked_frame.visible = false
	hide()


func _ready() -> void:
	focus_mode = FOCUS_NONE
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if 任务ID.is_empty() or disabled:
		return
	on_quest_slot_clicked.emit(slot_index)
