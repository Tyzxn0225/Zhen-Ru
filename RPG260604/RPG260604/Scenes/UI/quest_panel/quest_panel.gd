extends PanelContainer
class_name QuestPanel

const SLOT_SCENE := preload("res://Scenes/UI/quest_panel/quest_slot.tscn")

## 同时显示的任务条数，请在 ScrollContainer 检查器里调整高度与之对应
@export_range(1, 99) var visible_quest_count: int = 5
## 任务栏最多容纳的任务数（超出部分不显示，可滚动查看）
@export_range(1, 99) var total_quest_count: int = 10:
	set(value):
		total_quest_count = maxi(1, value)
		if is_node_ready():
			_ensure_slot_count(total_quest_count)
			refresh()

@onready var container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/Container
@onready var scroll: ScrollContainer = $MarginContainer/VBox/ScrollContainer

var _slots: Array[QuestSlot] = []


func _ready() -> void:
	visible = false
	_ensure_slot_count(total_quest_count)
	_connect_events()
	call_deferred("refresh")


func _connect_events() -> void:
	if not EventBus.任务已接取.is_connected(_on_quest_completed):
		EventBus.任务已接取.connect(_on_quest_completed)
	if not EventBus.任务阶段变化.is_connected(_on_quest_changed):
		EventBus.任务阶段变化.connect(_on_quest_changed)
	if not EventBus.任务已完成.is_connected(_on_quest_completed):
		EventBus.任务已完成.connect(_on_quest_completed)
	if not EventBus.任务关注变化.is_connected(_on_quest_panel_event):
		EventBus.任务关注变化.connect(_on_quest_panel_event)


func _on_quest_panel_event(_任务ID: String = "") -> void:
	call_deferred("refresh")


func _on_quest_changed(_任务ID: String, _阶段: int) -> void:
	call_deferred("refresh")


func _on_quest_completed(_任务ID: String) -> void:
	call_deferred("refresh")


func refresh() -> void:
	var display_list := QuestSystem.获取面板显示列表()
	var show_count := mini(display_list.size(), total_quest_count)

	for i in _slots.size():
		var slot := _slots[i]
		if i < show_count:
			var quest_id: String = display_list[i]
			slot.set_quest(
				quest_id,
				QuestSystem.获取任务标题(quest_id),
				QuestSystem.获取任务描述(quest_id),
				quest_id == QuestSystem.获取关注任务ID(),
				QuestSystem.是否已完成(quest_id)
			)
		else:
			slot.clear_slot()


func _ensure_slot_count(count: int) -> void:
	while _slots.size() < count:
		var slot: QuestSlot = SLOT_SCENE.instantiate()
		slot.slot_index = _slots.size()
		if not slot.on_quest_slot_clicked.is_connected(_on_quest_slot_clicked):
			slot.on_quest_slot_clicked.connect(_on_quest_slot_clicked)
		container.add_child(slot)
		_slots.append(slot)

	while _slots.size() > count:
		var slot: QuestSlot = _slots.pop_back()
		slot.queue_free()


func _on_quest_slot_clicked(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return
	var slot := _slots[slot_index]
	if slot.任务ID.is_empty() or QuestSystem.是否已完成(slot.任务ID):
		return
	QuestSystem.设置关注(slot.任务ID)
	refresh()
	if scroll:
		scroll.scroll_vertical = 0
