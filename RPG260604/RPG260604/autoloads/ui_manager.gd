# UIManager (Autoload) — 跨场景 UI 管理器
#
# 交互提示: 世界空间 InteractMarker (运行时生成 / 复用场景内已有实例)
# 屏幕文字提示: ToastHint 左下角小字 (奖励 / 教程 / 物品描述等)
# MainButtons 通过 CanvasLayer 挂在 get_tree().root 上

extends Node

signal custom_hint_hidden

const MAIN_BUTTONS_PATH := "res://Scenes/UI/main_buttons/main_buttons.tscn"
const INTERACT_MARKER_PATH := "res://Scenes/interact/InteractMarker.tscn"

# 始终显示MainButtons的场景列表
const ALWAYS_VISIBLE_SCENES := ["town.tscn"]

var toast_hint: PanelContainer
var _toast_title: Label
var _toast_detail: Label
var _hint_tween: Tween

var main_buttons: CanvasLayer

var custom_hint_active: bool = false
var interaction_hints_suppressed: bool = false
var _dialogue_active: bool = false

# InteractMarker 运行时管理 — key: 可交互对象, value: marker 实例
var _marker_by_interactable: Dictionary = {}
# true = UIManager 运行时创建, false = 场景中已有
var _owned_markers: Dictionary = {}
# 关注任务目标节点（范围外也显示金色 InteractMarker），任务变化时更新
var _quest_hint_nodes: Dictionary = {}


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	call_deferred("_setup")


func _setup() -> void:
	_setup_main_buttons()
	_bind_toast_hint()
	
	# 监听场景切换 (原生 Godot)
	get_tree().scene_changed.connect(_on_scene_changed)
	# 监听场景切换 (LongSceneManager)
	LongSceneManager.scene_switch_completed.connect(_on_scene_changed)
	# 监听暂停/恢复事件
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.on_dialogue_input_blocked.connect(_on_dialogue_input_blocked)


func _bind_toast_hint() -> void:
	if not main_buttons:
		return
	toast_hint = main_buttons.get_node_or_null("%ToastHint") as PanelContainer
	_toast_title = main_buttons.get_node_or_null("%TitleLabel") as Label
	_toast_detail = main_buttons.get_node_or_null("%DetailLabel") as Label
	if not toast_hint or not _toast_title or not _toast_detail:
		push_error("UIManager: ToastHint 绑定失败，请确认 main_buttons.tscn 中存在 %ToastHint / %TitleLabel / %DetailLabel")
		return
	print("UIManager: ToastHint 已绑定 (TitleLabel / DetailLabel)")


func _setup_main_buttons() -> void:
	main_buttons = load(MAIN_BUTTONS_PATH).instantiate()
	get_tree().root.add_child(main_buttons)
	
	# 默认先隐藏，稍后根据场景决定是否显示
	main_buttons.visible = false
	print("UIManager: MainButtons 初始化为隐藏")
	
	# 初始化时根据当前场景设置可见性
	var current_scene := get_tree().current_scene
	if current_scene:
		var scene_path: String = current_scene.get_scene_file_path()
		if scene_path.is_empty():
			print("UIManager: 场景路径为空")
		else:
			var scene_name: String = scene_path.get_file().to_lower()
			print("UIManager: 当前场景路径=", scene_path)
			print("UIManager: 当前场景名=", scene_name)
			
			# 检查场景名称是否包含town（不区分大小写）
			var is_town_scene: bool = scene_name.find("town") != -1
			print("UIManager: 是否town场景=", is_town_scene)
			
			main_buttons.visible = is_town_scene
			print("UIManager: 设置 MainButtons.visible = ", main_buttons.visible)
	else:
		print("UIManager: 当前场景为空")
	
	print("UIManager: MainButtons 初始化完成  canvas=", main_buttons, " 最终 visible=", main_buttons.visible)


# 屏幕左下角小字提示 — 独立于世界空间 InteractMarker
# 用于: 教程 / 物品描述 / 对话奖励提示 (show_timed_hint) 等

func show_custom_hint(title_text: String, detail_text: String = "") -> void:
	if not toast_hint:
		return
	_cancel_hint_tween()
	custom_hint_active = true
	if _toast_title:
		_toast_title.text = title_text
	if _toast_detail:
		_toast_detail.text = detail_text
		_toast_detail.visible = not detail_text.is_empty()
	toast_hint.visible = true


func show_timed_hint(title_text: String, detail_text: String, duration: float) -> void:
	show_custom_hint(title_text, detail_text)
	_hint_tween = create_tween()
	_hint_tween.tween_interval(duration)
	_hint_tween.tween_callback(func():
		if custom_hint_active:
			hide_custom_hint()
	)


func hide_custom_hint() -> void:
	if not toast_hint:
		return
	_cancel_hint_tween()
	custom_hint_active = false
	toast_hint.visible = false
	custom_hint_hidden.emit()
	_restore_world_interaction_hints()


func _cancel_hint_tween() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = null


#region ── 世界空间交互提示 (InteractMarker) ───────────────────────────────────

func set_interaction_hints_suppressed(suppressed: bool) -> void:
	interaction_hints_suppressed = suppressed
	if suppressed:
		hide_all_interaction_hints()
	else:
		_restore_world_interaction_hints()


## Player 在范围内对象或选中变化时调用
func update_interaction_hints(interactables: Array, current_index: int) -> void:
	if interaction_hints_suppressed:
		hide_all_interaction_hints()
		return

	var quest_node_set := _quest_hint_nodes
	var active: Dictionary = {}

	for i in interactables.size():
		var node: Node = interactables[i]
		if not is_instance_valid(node) or not Interactable.is_interactable(node):
			continue
		active[node] = {
			"focused": i == current_index,
			"quest": quest_node_set.has(node),
		}

	for node in _quest_hint_nodes:
		if not is_instance_valid(node) or active.has(node):
			continue
		active[node] = {
			"focused": false,
			"quest": true,
		}

	_apply_interaction_hint_states(active)


func refresh_quest_interaction_hints() -> void:
	if interaction_hints_suppressed:
		return
	_rebuild_quest_hint_nodes()
	if Refs.player and is_instance_valid(Refs.player):
		if Refs.player.has_method("_update_interaction_hints"):
			Refs.player._update_interaction_hints()
		elif Refs.player.has_method("refresh_interaction_hints"):
			Refs.player.refresh_interaction_hints()
		return
	_apply_quest_only_hints()


func _rebuild_quest_hint_nodes() -> void:
	_quest_hint_nodes.clear()
	for node in QuestSystem.获取任务交互节点表().values():
		if node and is_instance_valid(node):
			_quest_hint_nodes[node] = true


func _apply_interaction_hint_states(active: Dictionary) -> void:
	for node in active:
		var marker := _get_or_create_marker(node)
		marker.configure_for(node)
		marker.show_hint()
		var state: Dictionary = active[node]
		var focused: bool = state.get("focused", false)
		var quest: bool = state.get("quest", false)
		marker.set_focused(focused)
		marker.set_quest_tracked(quest and not focused)

	for node in _marker_by_interactable.keys():
		if not active.has(node) or not is_instance_valid(node):
			_release_marker(node)


func _apply_quest_only_hints() -> void:
	_rebuild_quest_hint_nodes()
	var active: Dictionary = {}
	for node in _quest_hint_nodes:
		if is_instance_valid(node):
			active[node] = { "focused": false, "quest": true }
	_apply_interaction_hint_states(active)


func hide_all_interaction_hints() -> void:
	for node in _marker_by_interactable.keys():
		var marker: InteractMarker = _marker_by_interactable[node]
		if is_instance_valid(marker):
			marker.hide_hint()


func _get_or_create_marker(interactable: Node) -> InteractMarker:
	if _marker_by_interactable.has(interactable):
		var cached: InteractMarker = _marker_by_interactable[interactable]
		if is_instance_valid(cached):
			return cached

	var preplaced := Interactable.find_existing_marker(interactable)
	if preplaced:
		_marker_by_interactable[interactable] = preplaced
		_owned_markers[interactable] = false
		preplaced.configure_for(interactable)
		return preplaced

	var parent := Interactable.get_hint_parent(interactable)
	var marker: InteractMarker = load(INTERACT_MARKER_PATH).instantiate()
	parent.add_child(marker)
	marker.configure_for(interactable)
	_marker_by_interactable[interactable] = marker
	_owned_markers[interactable] = true
	return marker


func _release_marker(interactable: Node) -> void:
	if not _marker_by_interactable.has(interactable):
		return
	var marker: InteractMarker = _marker_by_interactable[interactable]
	var owned: bool = _owned_markers.get(interactable, false)
	_marker_by_interactable.erase(interactable)
	_owned_markers.erase(interactable)
	if not is_instance_valid(marker):
		return
	if owned:
		marker.queue_free()
	else:
		marker.hide_hint()


func _clear_all_interaction_markers() -> void:
	for node in _marker_by_interactable.duplicate().keys():
		_release_marker(node)


func _restore_world_interaction_hints() -> void:
	if interaction_hints_suppressed:
		return
	if Refs.player and is_instance_valid(Refs.player):
		Refs.player.call_deferred("refresh_interaction_hints")

#endregion


# 根据当前场景设置MainButtons可见性
# 参数 scene_path_from_signal: LongSceneManager 的信号会传入场景路径
func _on_scene_changed(_scene_path_from_signal: String = "") -> void:
	_clear_all_interaction_markers()
	_quest_hint_nodes.clear()
	interaction_hints_suppressed = false

	if not main_buttons:
		print("UIManager: _on_scene_changed - main_buttons为空")
		return

	refresh_main_buttons_visibility()


func refresh_main_buttons_visibility() -> void:
	if not main_buttons:
		return

	if PauseManager.is_paused or _dialogue_active:
		main_buttons.visible = true
		return

	var current_scene := get_tree().current_scene
	if current_scene:
		var scene_path: String = current_scene.get_scene_file_path()
		var scene_name: String = scene_path.get_file().to_lower()
		var is_town_scene: bool = scene_name.find("town") != -1
		main_buttons.visible = is_town_scene
	else:
		main_buttons.visible = false


func _on_dialogue_input_blocked(is_blocked: bool) -> void:
	_dialogue_active = is_blocked
	refresh_main_buttons_visibility()


# 暂停时显示 MainButtons，并置于暂停菜单之上以便交互
func _on_game_paused() -> void:
	if not main_buttons:
		print("UIManager: _on_game_paused - main_buttons为空")
		return

	refresh_main_buttons_visibility()


# 恢复时隐藏MainButtons（非town场景，且不在对话中）
func _on_game_resumed() -> void:
	if not main_buttons:
		print("UIManager: _on_game_resumed - main_buttons为空")
		return

	refresh_main_buttons_visibility()


# ==================== 统一场景切换系统 ====================

##
# 带转场动画的跨场景切换
# 统一了 Portal 和 Dialogue 的场景切换逻辑
#
# @param target_scene_path: 目标场景路径
# @param player: 玩家节点实例（用于保存状态），为空则使用 Refs.player
# @param return_scene_path: 返回场景路径，为空则自动使用当前场景
# @param fade_in_speed: 淡入速度（秒）
# @param fade_out_speed: 淡出速度（秒）
# @param use_current_as_return: 是否将当前场景作为返回点（默认 true）
##
func switch_scene_with_transition(
	target_scene_path: String,
	player: Player = null,
	return_scene_path: String = "",
	fade_in_speed: float = 0.5,
	fade_out_speed: float = 0.5,
	use_current_as_return: bool = true
) -> void:
	switch_scene_with_transition_async(target_scene_path, player, return_scene_path, fade_in_speed, fade_out_speed, use_current_as_return)


func switch_scene_with_transition_async(
	target_scene_path: String,
	player: Player = null,
	return_scene_path: String = "",
	fade_in_speed: float = 0.5,
	fade_out_speed: float = 0.5,
	use_current_as_return: bool = true
) -> void:
	# 验证目标场景
	if target_scene_path.is_empty():
		push_error("UIManager: 目标场景路径为空")
		return
	if not ResourceLoader.exists(target_scene_path):
		push_error("UIManager: 目标场景不存在: ", target_scene_path)
		return
	
	# 1. 淡入转场
	await Transition.fade_in(fade_in_speed)
	
	# 2. 设置返回场景
	if not return_scene_path.is_empty():
		GameData.return_scene = return_scene_path
	elif use_current_as_return:
		GameData.return_scene = get_tree().current_scene.scene_file_path
	
	# 3. 保存玩家数据
	var player_to_save: Player = player if player and is_instance_valid(player) else Refs.player
	if player_to_save and is_instance_valid(player_to_save):
		GameData.save_player_data(player_to_save)
	
	# 4. 清理目标场景的缓存
	LongSceneManager.remove_cached_scene(target_scene_path)
	LongSceneManager.remove_temp_resource(target_scene_path)
	LongSceneManager.remove_fixed_resource(target_scene_path)
	
	# 5. 切换场景
	LongSceneManager.switch_scene(target_scene_path, LongSceneManager.LoadMethod.BOTH_PRELOAD_FIRST, true, "no_transition")
	
	# 6. 等待一帧确保场景切换完成
	if get_tree():
		await get_tree().process_frame
	
	# 7. 淡出转场
	Transition.fade_out(fade_out_speed)
