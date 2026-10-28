class_name QuestData
extends Resource

## 任务 ID，与对话中 QuestSystem.接取任务("...") 的参数一致
@export var quest_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var stages: Array[QuestStageData] = []


func 获取阶段数量() -> int:
	return stages.size()


func 获取阶段提示(阶段索引: int) -> String:
	if 阶段索引 < 0 or 阶段索引 >= stages.size():
		return ""
	var stage := stages[阶段索引]
	return stage.hint if stage else ""


func 获取阶段名称(阶段索引: int) -> String:
	if 阶段索引 < 0 or 阶段索引 >= stages.size():
		return ""
	var stage := stages[阶段索引]
	if stage and not stage.stage_name.is_empty():
		return stage.stage_name
	return "阶段 %d" % (阶段索引 + 1)


func 获取阶段地图标记(阶段索引: int) -> String:
	var ids := 获取阶段地图标记列表(阶段索引)
	return ids[0] if not ids.is_empty() else ""


func 获取阶段地图标记列表(阶段索引: int) -> Array[String]:
	if 阶段索引 < 0 or 阶段索引 >= stages.size():
		return []
	var stage := stages[阶段索引]
	if stage == null:
		return []
	var result: Array[String] = []
	for id in stage.map_marker_ids:
		if not id.is_empty() and not result.has(id):
			result.append(id)
	if not stage.map_marker_id.is_empty() and not result.has(stage.map_marker_id):
		result.append(stage.map_marker_id)
	return result
