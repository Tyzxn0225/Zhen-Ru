extends Node
## 任务系统 — 状态存储、对话 API、地图标记刷新

enum 任务状态 { 未接取, 进行中, 已完成 }

const _QUEST_DIR := "res://data/quests/"
const MINI_QUEST_MARKER_SCENE := preload("res://Scenes/quest/mini_quest_marker.tscn")

var _任务资源: Dictionary = {}   # 任务ID -> QuestData
var _运行时: Dictionary = {}     # 任务ID -> { "状态", "阶段" }  阶段为 0-based 当前阶段索引
var _接取顺序: Array[String] = [] # 面板排序：关注任务置顶
var _当前关注: String = ""
var _活跃标记: Dictionary = {}   # map_marker_id -> MiniQuestMarker（运行时生成）
var _marker_id_to_interactable: Dictionary = {}  # 关注任务当前阶段 marker_id -> Node（任务刷新时重建）


func _ready() -> void:
	_加载全部任务资源()


func _加载全部任务资源() -> void:
	_任务资源.clear()
	var dir := DirAccess.open(_QUEST_DIR)
	if dir == null:
		push_warning("QuestSystem: 找不到任务目录 ", _QUEST_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: QuestData = load(_QUEST_DIR + file_name)
			if res == null:
				push_warning("QuestSystem: 无法加载 ", file_name)
				file_name = dir.get_next()
				continue
			var id := res.quest_id
			if id.is_empty():
				id = file_name.get_basename()
				push_warning("QuestSystem: %s 未设置 quest_id，已使用文件名「%s」" % [file_name, id])
			if id.is_empty():
				file_name = dir.get_next()
				continue
			if res.title.is_empty():
				res.title = id
			_任务资源[id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func 接取任务(任务ID: String) -> void:
	if not _任务资源.has(任务ID):
		push_error("QuestSystem: 未知任务「%s」，请检查 data/quests/ 下对应 .tres 是否设置了 quest_id" % 任务ID)
		return
	var 状态 := 获取状态(任务ID)
	if 状态 == 任务状态.进行中 or 状态 == 任务状态.已完成:
		return
	_运行时[任务ID] = { "状态": 任务状态.进行中, "阶段": 0 }
	if not _接取顺序.has(任务ID):
		_接取顺序.append(任务ID)
	if _当前关注.is_empty():
		_当前关注 = 任务ID
	_schedule_refresh_map_markers()
	_刷新任务栏框()
	EventBus.任务已接取.emit(任务ID)
	EventBus.任务阶段变化.emit(任务ID, 0)


## 完成指定阶段（阶段号从 1 开始，与策划编号一致）
func 完成阶段(任务ID: String, 阶段号: int) -> void:
	if 获取状态(任务ID) != 任务状态.进行中:
		return
	var data: QuestData = _任务资源.get(任务ID)
	if data == null:
		return
	var 目标索引 := 阶段号  # 完成第 N 阶段后，当前阶段索引变为 N（进入下一阶段）
	if 目标索引 < 0 or 目标索引 > data.获取阶段数量():
		push_warning("QuestSystem: 无效阶段号 ", 阶段号, " / ", 任务ID)
		return
	_运行时[任务ID]["阶段"] = 目标索引
	if 目标索引 >= data.获取阶段数量():
		_运行时[任务ID]["状态"] = 任务状态.已完成
		if _当前关注 == 任务ID:
			_当前关注 = ""
		EventBus.任务已完成.emit(任务ID)
	else:
		EventBus.任务阶段变化.emit(任务ID, 目标索引)
	_schedule_refresh_map_markers()
	_刷新任务栏框()


func 设置阶段(任务ID: String, 阶段索引: int) -> void:
	if 获取状态(任务ID) != 任务状态.进行中:
		return
	var data: QuestData = _任务资源.get(任务ID)
	if data == null:
		return
	_运行时[任务ID]["阶段"] = clampi(阶段索引, 0, data.获取阶段数量())
	if _运行时[任务ID]["阶段"] >= data.获取阶段数量():
		_运行时[任务ID]["状态"] = 任务状态.已完成
		if _当前关注 == 任务ID:
			_当前关注 = ""
		EventBus.任务已完成.emit(任务ID)
	else:
		EventBus.任务阶段变化.emit(任务ID, _运行时[任务ID]["阶段"])
	_schedule_refresh_map_markers()
	_刷新任务栏框()


func 设置关注(任务ID: String) -> void:
	if 获取状态(任务ID) != 任务状态.进行中:
		return
	var order := _获取进行中显示顺序()
	var idx := order.find(任务ID)
	if idx < 0:
		return
	# 与当前顶端 slot 的任务互换（idx==0 时仅刷新关注高亮）
	if idx > 0:
		var top_id: String = order[0]
		order[0] = 任务ID
		order[idx] = top_id
	_当前关注 = 任务ID
	_重排进行中任务(order)
	_schedule_refresh_map_markers()
	_刷新任务栏框()
	EventBus.任务关注变化.emit(任务ID)


func _获取进行中显示顺序() -> Array[String]:
	var result: Array[String] = []
	var tracked := _当前关注
	if not tracked.is_empty() and 是否进行中(tracked):
		result.append(tracked)
	for quest_id in _接取顺序:
		if quest_id == tracked:
			continue
		if 是否进行中(quest_id):
			result.append(quest_id)
	return result


func _重排进行中任务(active_order: Array[String]) -> void:
	var active_index := 0
	var new_order: Array[String] = []
	for quest_id in _接取顺序:
		if 是否进行中(quest_id):
			if active_index < active_order.size():
				new_order.append(active_order[active_index])
				active_index += 1
			else:
				new_order.append(quest_id)
		else:
			new_order.append(quest_id)
	while active_index < active_order.size():
		new_order.append(active_order[active_index])
		active_index += 1
	_接取顺序 = new_order


func 获取状态(任务ID: String) -> 任务状态:
	if not _运行时.has(任务ID):
		return 任务状态.未接取
	return _运行时[任务ID]["状态"]


func 是否进行中(任务ID: String) -> bool:
	return 获取状态(任务ID) == 任务状态.进行中


func 是否已完成(任务ID: String) -> bool:
	return 获取状态(任务ID) == 任务状态.已完成


## 返回当前阶段号（1-based）；未接取或已完成时返回 0
func 获取阶段(任务ID: String) -> int:
	if 获取状态(任务ID) != 任务状态.进行中:
		return 0
	return _运行时[任务ID]["阶段"] + 1


func 获取关注任务ID() -> String:
	return _当前关注


func 获取关注提示() -> String:
	return 获取关注阶段目标()


func 获取关注阶段名() -> String:
	if _当前关注.is_empty():
		return ""
	var data: QuestData = _任务资源.get(_当前关注)
	if data == null or not _运行时.has(_当前关注):
		return ""
	if 获取状态(_当前关注) != 任务状态.进行中:
		return ""
	var idx: int = _运行时[_当前关注]["阶段"]
	return data.获取阶段名称(idx)


func 获取关注阶段目标() -> String:
	if _当前关注.is_empty():
		return ""
	var data: QuestData = _任务资源.get(_当前关注)
	if data == null or not _运行时.has(_当前关注):
		return ""
	if 获取状态(_当前关注) != 任务状态.进行中:
		return ""
	var idx: int = _运行时[_当前关注]["阶段"]
	return data.获取阶段提示(idx)


func 获取任务标题(任务ID: String) -> String:
	var data: QuestData = _任务资源.get(任务ID)
	return data.title if data else ""


func 获取任务描述(任务ID: String) -> String:
	var data: QuestData = _任务资源.get(任务ID)
	return data.description if data else ""


## 返回全部任务（进行中优先、关注置顶，已完成在后）；显示数量由 QuestPanel 滚动区承载
func 获取面板显示列表() -> Array[String]:
	var result: Array[String] = []
	var tracked := _当前关注
	if not tracked.is_empty() and 是否进行中(tracked):
		result.append(tracked)
	for quest_id in _接取顺序:
		if quest_id == tracked:
			continue
		if 是否进行中(quest_id):
			result.append(quest_id)
	for quest_id in _接取顺序:
		if 是否已完成(quest_id):
			result.append(quest_id)
	return result


func 获取进行中任务列表() -> Array[String]:
	var result: Array[String] = []
	for 任务ID in _运行时:
		if _运行时[任务ID]["状态"] == 任务状态.进行中:
			result.append(任务ID)
	return result


func 获取已完成任务列表() -> Array[String]:
	var result: Array[String] = []
	for 任务ID in _运行时:
		if _运行时[任务ID]["状态"] == 任务状态.已完成:
			result.append(任务ID)
	return result


func _刷新地图标记() -> void:
	if not is_inside_tree():
		return
	var needed := _收集活跃地图标记()
	for marker_id in _活跃标记.keys():
		if needed.has(marker_id):
			continue
		_release_quest_marker(marker_id)
	for marker_id in needed:
		var marker := _get_or_create_quest_marker(marker_id)
		if marker == null:
			continue
		marker.visible = true
		marker.set_tracked(needed[marker_id])

	_rebuild_interactable_cache()
	_refresh_quest_interaction_hints()


func _rebuild_interactable_cache() -> void:
	_marker_id_to_interactable.clear()
	for marker_id in _收集关注任务阶段标记():
		if marker_id.is_empty():
			continue
		var node := Interactable.find_quest_interactable(marker_id)
		if node and is_instance_valid(node):
			_marker_id_to_interactable[marker_id] = node


func _收集关注任务阶段标记() -> Array[String]:
	if _当前关注.is_empty() or not 是否进行中(_当前关注):
		return []
	var data: QuestData = _任务资源.get(_当前关注)
	if data == null or not _运行时.has(_当前关注):
		return []
	var idx: int = _运行时[_当前关注]["阶段"]
	return data.获取阶段地图标记列表(idx)


func _get_or_create_quest_marker(marker_id: String) -> MiniQuestMarker:
	var anchor := MiniQuestMarker.find_spawn_parent(marker_id)
	if _活跃标记.has(marker_id):
		var cached: MiniQuestMarker = _活跃标记[marker_id]
		if is_instance_valid(cached):
			if anchor:
				cached.bind_anchor(anchor)
				cached.global_position = MiniQuestMarker.get_spawn_global_position(anchor)
			return cached
	if anchor == null:
		push_warning(
			"QuestSystem: 找不到 map_marker_id「%s」——须与场景中同名 NPC 或建筑 StaticBody2D 节点一致"
			% marker_id
		)
		return null
	var mount := get_tree().current_scene
	if mount == null:
		return null
	var marker: MiniQuestMarker = MINI_QUEST_MARKER_SCENE.instantiate()
	mount.add_child(marker)
	marker.bind_anchor(anchor)
	marker.global_position = MiniQuestMarker.get_spawn_global_position(anchor)
	marker.setup(marker_id, null)
	_活跃标记[marker_id] = marker
	return marker


func _release_quest_marker(marker_id: String) -> void:
	if not _活跃标记.has(marker_id):
		return
	var marker: MiniQuestMarker = _活跃标记[marker_id]
	_活跃标记.erase(marker_id)
	if is_instance_valid(marker):
		marker.queue_free()


func 刷新地图标记() -> void:
	_刷新地图标记()


func _schedule_refresh_map_markers() -> void:
	call_deferred("刷新地图标记")


func _收集活跃地图标记() -> Dictionary:
	# map_marker_id -> 是否为关注任务
	var result: Dictionary = {}
	for quest_id in 获取进行中任务列表():
		var data: QuestData = _任务资源.get(quest_id)
		if data == null or not _运行时.has(quest_id):
			continue
		var idx: int = _运行时[quest_id]["阶段"]
		var marker_ids := data.获取阶段地图标记列表(idx)
		var tracked: bool = quest_id == _当前关注
		for marker_id in marker_ids:
			if marker_id.is_empty():
				continue
			if result.has(marker_id):
				result[marker_id] = bool(result[marker_id]) or tracked
			else:
				result[marker_id] = tracked
	return result


## 供 UIManager 显示任务 InteractMarker；map_marker_id -> 是否来自关注任务
func 获取活跃地图标记表() -> Dictionary:
	return _收集活跃地图标记()


## 关注任务当前阶段的 marker_id -> 交互节点（仅用于 InteractMarker 金色描边）
func 获取任务交互节点表() -> Dictionary:
	return _marker_id_to_interactable


## 刷新 MainButtons 上的 Quest hint 任务追踪栏与任务面板
func _刷新任务栏框() -> void:
	if UIManager.main_buttons:
		if UIManager.main_buttons.has_method("refresh_quest_hint"):
			UIManager.main_buttons.refresh_quest_hint()
		if UIManager.main_buttons.has_method("refresh_quest_panel"):
			UIManager.main_buttons.refresh_quest_panel()
	if Refs.hud and Refs.hud.has_method("refresh_quest_tracker"):
		Refs.hud.refresh_quest_tracker()


func _refresh_quest_interaction_hints() -> void:
	if UIManager:
		UIManager.refresh_quest_interaction_hints()
