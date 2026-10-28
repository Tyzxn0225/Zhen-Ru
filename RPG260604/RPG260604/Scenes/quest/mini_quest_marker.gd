extends Node2D
class_name MiniQuestMarker

## 小地图专用层（主画面会隐藏 layer 2，SubViewport 小地图显示 layer 2）
const MINIMAP_VISIBILITY_LAYER := 2
const SLOT_NODE_NAME := "QuestMarkerSlot"

const DEFAULT_ICON := preload(
	"res://sample/570+Icons-v1.0.3/2.Media & Technology/location_64px.png"
)

@export var icon_scale: float = 3.0

@onready var _outline: Sprite2D = $Outline
@onready var _icon: Sprite2D = $Icon

var marker_id: String = ""
var _pulse_tween: Tween
var _follow_anchor: Node2D = null


func _ready() -> void:
	add_to_group("quest_markers")
	z_index = -19
	z_as_relative = false
	y_sort_enabled = false
	_apply_minimap_layers(self)
	if _icon and _icon.texture == null:
		_apply_icon(DEFAULT_ICON)
	visible = false


func setup(id: String, icon: Texture2D = null) -> void:
	marker_id = id
	if icon:
		_apply_icon(icon)
	elif _icon and _icon.texture == null:
		_apply_icon(DEFAULT_ICON)


func set_tracked(active: bool) -> void:
	if _outline == null:
		return
	_outline.visible = active
	if active:
		_start_pulse()
	else:
		_stop_pulse()


## 绑定锚点；NPC 会在 _process 中持续跟随，建筑仅定位一次
func bind_anchor(anchor: Node) -> void:
	_follow_anchor = anchor as Node2D if anchor is Node2D else null
	set_process(_follow_anchor is NPC)


func _process(_delta: float) -> void:
	if _follow_anchor == null or not is_instance_valid(_follow_anchor):
		set_process(false)
		_follow_anchor = null
		return
	global_position = get_spawn_global_position(_follow_anchor)


## 运行时查找锚点：仅匹配同名 NPC（CharacterBody2D）或建筑 StaticBody2D（BuildingOcclusion）
static func find_spawn_parent(marker_id: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or marker_id.is_empty():
		return null

	var candidates: Array[Node] = []
	if tree.current_scene:
		_collect_anchor_nodes_named(tree.current_scene, marker_id, candidates)
	for node in tree.get_nodes_in_group("quest_marker_hosts"):
		if node.name == marker_id and _is_quest_marker_anchor(node) and not candidates.has(node):
			candidates.append(node)

	return candidates[0] if not candidates.is_empty() else null


static func _is_quest_marker_anchor(node: Node) -> bool:
	return node is NPC or node is BuildingOcclusion


static func _collect_anchor_nodes_named(root: Node, node_name: String, out: Array[Node]) -> void:
	if root.name == node_name and _is_quest_marker_anchor(root) and not out.has(root):
		out.append(root)
	for child in root.get_children():
		_collect_anchor_nodes_named(child, node_name, out)


static func get_spawn_global_position(anchor: Node) -> Vector2:
	if anchor.has_method("get_quest_marker_global_position"):
		return anchor.get_quest_marker_global_position() as Vector2
	return Vector2.ZERO


func _apply_minimap_layers(node: Node) -> void:
	if node is CanvasItem:
		node.visibility_layer = MINIMAP_VISIBILITY_LAYER
	for child in node.get_children():
		_apply_minimap_layers(child)


func _apply_icon(tex: Texture2D) -> void:
	if _icon:
		_icon.texture = tex
		_icon.scale = Vector2.ONE * icon_scale
	if _outline:
		_outline.texture = tex
		_reset_outline_scale()


func _reset_outline_scale() -> void:
	if _outline:
		_outline.scale = Vector2.ONE * icon_scale * 1.35


func _start_pulse() -> void:
	_stop_pulse()
	_outline.modulate = Color(1, 0.88, 0.45, 0.85)
	_reset_outline_scale()
	var small := icon_scale * 1.25
	var large := icon_scale * 1.55
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_outline, "scale", Vector2.ONE * large, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_outline, "modulate:a", 0.35, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_outline, "scale", Vector2.ONE * small, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_outline, "modulate:a", 0.9, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	_reset_outline_scale()
	if _outline:
		_outline.modulate = Color(1, 0.88, 0.45, 0.85)
