class_name QuestStageData
extends Resource

## 阶段名称（Quest hint 标题栏）
@export var stage_name: String = ""
## 当前阶段的目标提示（Quest hint 详情栏）
@export var hint: String = ""
## 小地图 / InteractMarker 标记 ID（可填多个）；须与场景中同名 NPC 或建筑 StaticBody2D 一致
@export var map_marker_ids: Array[String] = []
## 兼容旧资源：单 ID 会自动并入 map_marker_ids
@export var map_marker_id: String = ""
