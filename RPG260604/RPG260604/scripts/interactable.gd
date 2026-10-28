class_name Interactable
extends RefCounted

enum HintStyle { TALK, PORTAL }

static func is_interactable(node: Node) -> bool:
	return node.has_method("interact") and node.has_method("get_interact_name") and (not node.has_method("can_interact") or node.can_interact())

static func get_obj_name(node: Node) -> String:
	if node.has_method("get_interact_name"):
		return node.get_interact_name()
	return node.name

static func get_obj_action(node: Node) -> String:
	if node.has_method("get_interact_action"):
		return node.get_interact_action()
	return "交互"

static func get_obj_priority(node: Node) -> int:
	if node.has_method("get_interact_priority"):
		return node.get_interact_priority()
	return 0

static func execute(node: Node, player: Player) -> void:
	if node.has_method("interact"):
		node.interact(player)


## 交互提示样式: NPC 对话 → talk, 传送门 → portal
static func get_hint_style(node: Node) -> HintStyle:
	if node.has_method("get_interact_hint_style"):
		return node.get_interact_hint_style()
	if node is Portal:
		return HintStyle.PORTAL
	return HintStyle.TALK


## 运行时 InteractMarker 的挂载父节点
static func get_hint_parent(node: Node) -> Node:
	if node.has_method("get_interact_hint_parent"):
		return node.get_interact_hint_parent()
	if node is Portal:
		for child in node.get_children():
			if child is CollisionShape2D:
				return child
	return node


## 查找场景中已手动放置的 InteractMarker（NPC 根节点 / Portal 的 CollisionShape2D 下）
static func find_existing_marker(interactable: Node) -> InteractMarker:
	var direct := _find_marker_among_children(interactable)
	if direct:
		return direct
	for child in interactable.get_children():
		var nested := _find_marker_among_children(child)
		if nested:
			return nested
	return null


static func _find_marker_among_children(node: Node) -> InteractMarker:
	for child in node.get_children():
		if child is InteractMarker:
			return child
	return null


## 任务 map_marker_id → 可显示 InteractMarker 的节点（NPC 或对应 Portal）
static func find_quest_interactable(marker_id: String) -> Node:
	if marker_id.is_empty():
		return null
	var anchor := MiniQuestMarker.find_spawn_parent(marker_id)
	if anchor is NPC:
		return anchor
	if anchor != null and anchor.has_method("interact") and anchor.has_method("get_interact_name"):
		return anchor
	return find_portal_by_marker_id(marker_id)


static func find_portal_by_marker_id(marker_id: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("portals"):
		if not is_interactable(node):
			continue
		if node.get_interact_name() == marker_id or node.name == marker_id:
			return node
	return null
