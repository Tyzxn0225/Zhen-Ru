extends CharacterBody2D
class_name NPC


#region ── NPC 类型枚举 ────────────────────────────────────────────────────────

enum NpcType {
	SHOP,      # 商店 NPC — 对话结束后打开商店面板
	IDLE,      # 纯对话 NPC — 对话结束后无额外操作
	QUEST,     # 任务 NPC — 最高优先级
	CRAFTING,  # 打造 NPC
}

#endregion


#region ── 导出变量 ────────────────────────────────────────────────────────────

# 对话资源 ( 二选一: DialogueResource 优先于 DialogueData )
@export var dialogue_manager: DialogueResource
@export var dialogue: DialogueData

@export var type: NpcType

@export_group("Movement")
@export var can_move: bool = true                     # 是否启用自动寻路移动
@export var move_speed: float = 30             # 移动速度
@export var wait_time: float = 3.0             # 到达目标后原地等待的秒数
@export var movement_radius: float = 0.0       # 活动半径 ( 0 = 不限制范围, 使用全部导航网格 )
@export var movement_center: Vector2 = Vector2.ZERO  # 活动中心 ( ZERO = 自动设为 NPC 出生位置 )
@export var navigation_map: TileMapLayer              # 导航地图 ( 为空时自动使用 Refs.navigation )

@export_group("Interaction Behavior")
@export var face_player_on_interact: bool = true  # 交互时是否面向玩家, 关闭则保持原始朝向

@export_group("Quest")
## 任务标记相对本 NPC 根节点的局部坐标；也可放子节点 QuestMarkerSlot，使用其 global_position
@export var quest_marker_offset: Vector2 = Vector2.ZERO

#endregion


#region ── 场景节点引用 ────────────────────────────────────────────────────────

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer

#endregion


#region ── 运行时状态 ──────────────────────────────────────────────────────────

var last_direction: String = "down"            # 当前朝向, 用于动画索引

var _is_interacting: bool = false              # 是否正在与玩家交互 ( 对话中 )
var _movement_paused: bool = false             # 是否因交互而暂停移动
var _in_story_movement: bool = false           # 是否正在进行剧情移动（子类 StoryNPC 会设置为 true）
var _pre_interact_direction: String = ""        # 交互前的朝向 ( 非 can_move 时用于恢复 )
var _face_held: bool = false                   # face_direction() 是否设置了强制朝向
var _story_tween: Tween                         # 剧情移动用的 Tween

# 卡住检测 — move_and_slide 被阻挡时自动换目标
var _stuck_timer: float = 0.0
var _last_stuck_check_pos: Vector2
const STUCK_TIMEOUT: float = 1.0            # 原地不动超过此秒数视为卡住
const STUCK_MOVE_THRESHOLD: float = 6.0     # 检测周期内位移低于此像素视为未移动

# 导航地图: export 优先, 否则回退到 Refs.navigation
var _nav_map: TileMapLayer:
	get:
		if navigation_map:
			return navigation_map
		return Refs.navigation

#endregion


#region ── 生命周期 ────────────────────────────────────────────────────────────

func _ready() -> void:
	# 从 AnimatedSprite2D 当前动画自动检测初始朝向 (如 "idle_up" → "up")
	_detect_initial_direction()

	# 连接对话状态信号 — 用于检测对话何时结束, 以便恢复 NPC 状态
	EventBus.on_dialogue_input_blocked.connect(_on_dialogue_input_blocked)

	# 连接剧情移动信号（所有 NPC 都可被对话 do 命令移动）
	if not EventBus.npc_story_move_request.is_connected(_on_npc_story_move_request):
		EventBus.npc_story_move_request.connect(_on_npc_story_move_request)

	# 未手动设置活动中心时, 自动以出生位置为中心
	if movement_center == Vector2.ZERO:
		movement_center = global_position

	if not can_move:
		print("NPC %s: can_move is false, movement disabled" % name)
		return

	await get_tree().process_frame

	if not _nav_map:
		print("NPC %s: 导航地图为空 (export 未指定且 Refs.navigation 不存在), cannot move" % name)
		return

	timer.stop()
	set_new_target()
	print("NPC %s: Movement enabled, target set" % name)


func _process(delta: float) -> void:
	if not can_move or _movement_paused or _in_story_movement:
		return

	if is_waiting_for_next_move():
		play_animation("idle")
		return

	if has_reached_target():
		if timer.is_stopped():
			timer.start(wait_time)
		return

	# 沿导航路径移动 — 用 move_and_slide 参与碰撞检测
	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_path_pos)
	velocity = direction * move_speed
	move_and_slide()

	# 卡住检测: 超时未移动则换目标
	_stuck_timer += delta
	if _stuck_timer >= STUCK_TIMEOUT:
		_stuck_timer = 0.0
		if global_position.distance_squared_to(_last_stuck_check_pos) < STUCK_MOVE_THRESHOLD * STUCK_MOVE_THRESHOLD:
			print("NPC %s: stuck, choosing new target" % name)
			set_new_target()
		_last_stuck_check_pos = global_position

	update_direction(direction)
	play_animation("move")

#endregion


#region ── 交互协议实现 ────────────────────────────────────────────────────────

# 返回 NPC 名称 — 对应编辑器中的节点名 ( 如 "铁匠老王" )
func get_interact_name() -> String:
	return name


func get_quest_marker_offset() -> Vector2:
	return quest_marker_offset


func get_quest_marker_global_position() -> Vector2:
	var slot := get_node_or_null(MiniQuestMarker.SLOT_NODE_NAME) as Node2D
	if slot:
		return slot.global_position
	return to_global(quest_marker_offset)


# 根据 NPC 类型返回不同的动作描述词
# SHOP → "交易" / QUEST → "任务" / CRAFTING → "打造" / 其他 → "对话"
func get_interact_action() -> String:
	match type:
		NpcType.SHOP:     return "交易"
		NpcType.QUEST:    return "任务"
		NpcType.CRAFTING: return "打造"
		_:                return "对话"


# 交互优先级: 任务 (10) > 商店 (8) > 其他 (3)
func get_interact_priority() -> int:
	match type:
		NpcType.QUEST: return 10
		NpcType.SHOP:  return 8
		_:             return 3


# 检查 NPC 是否可以被交互：必须有 dialogue_manager 或 dialogue，否则不进入交互列表
func can_interact() -> bool:
	return dialogue_manager != null or dialogue != null


# Player 按 E 键时由交互系统调用
func interact(player: Player) -> void:
	# 无对话资源时不做任何事，也不进入 _is_interacting（避免卡在交互状态）
	if not dialogue_manager and not dialogue:
		return

	_begin_interaction(player)

	if dialogue_manager:
		DialogueManager.show_dialogue_balloon(dialogue_manager)
	elif dialogue:
		EventBus.on_dialogue_started.emit(dialogue)
		if type != NpcType.IDLE:
			await EventBus.on_dialogue_finished
			Refs.hud.open_npc_panel(type)


## 强制 NPC 面朝指定方向，锁定后不再自动面朝玩家
## 用法: do Refs.current_npc.face_direction("left")
##       do Refs.get_npc_by_name("学姐A").face_direction("up")
func face_direction(direction: String) -> void:
	_face_held = true
	last_direction = direction
	play_animation("idle")


## 取消强制朝向，恢复默认自动面朝玩家
## 用法: do Refs.current_npc.release_face_direction()
##       do Refs.get_npc_by_name("学姐A").release_face_direction()
func release_face_direction() -> void:
	if not _face_held:
		return
	_face_held = false
	# 立即面朝玩家
	if Refs.player:
		var dir := global_position.direction_to(Refs.player.global_position)
		update_direction(dir)
		play_animation("idle")


## 瞬间传送到目标坐标（无动画，直接跳转）
## 用法: do Refs.current_npc.teleport_to(Vector2(500, -300))
##       do Refs.get_npc_by_name("学姐A").teleport_to(Vector2(852, -4216))
func teleport_to(target: Vector2) -> void:
	global_position = target

#endregion


#region ── 交互开始 & 结束 ──────────────────────────────────────────────────────

# 交互开始: 保存当前状态, 面向玩家, 暂停移动
func _begin_interaction(player: Player) -> void:
	_is_interacting = true
	Refs.current_npc = self

	if face_player_on_interact and not _face_held:
		_pre_interact_direction = last_direction
		var dir := global_position.direction_to(player.global_position)
		update_direction(dir)
		play_animation("idle")

	if can_move:
		_movement_paused = true


# 对话结束时由 EventBus 信号触发, 恢复 NPC 移动 / 朝向
func _on_dialogue_input_blocked(is_blocked: bool) -> void:
	if is_blocked:
		return                          # 对话开始, 不做额外处理
	if not _is_interacting:
		return                          # 不是本 NPC 的对话, 忽略

	_is_interacting = false
	_face_held = false                 # 对话结束, 清除朝向锁定

	# 故事移动进行中: 不要恢复交互前朝向, 也不要解锁 _movement_paused
	# 保持当前移动状态, 等故事移动完成时由 _on_story_move_complete 统一处理
	if _in_story_movement:
		_movement_paused = true
		_pre_interact_direction = ""
		return

	if can_move:
		_movement_paused = false        # 恢复移动
		# 恢复交互前的朝向, 避免短暂显示面向玩家的朝向 ( 下一帧 _process 会根据移动方向更新 )
		if face_player_on_interact and not _pre_interact_direction.is_empty():
			last_direction = _pre_interact_direction
			play_animation("idle")
	else:
		# 非移动 NPC: 恢复到交互前的朝向
		if face_player_on_interact and not _pre_interact_direction.is_empty():
			last_direction = _pre_interact_direction
			play_animation("idle")
	_pre_interact_direction = ""

#endregion


#region ── 剧情移动 (信号驱动, 供 dialogue do 调用) ────────────────────────────

# 响应 EventBus.request_npc_story_move 信号
func _on_npc_story_move_request(npc_name: String, waypoints: Array, speed: float) -> void:
	if name == npc_name:
		move_waypoints(waypoints, speed)


# 多点航点移动 (tween 方式, 不依赖 NavigationAgent2D)
func move_waypoints(waypoints: Array, speed_override: float = -1.0) -> void:
	var spd := speed_override if speed_override > 0 else move_speed * 2.0
	_in_story_movement = true
	_movement_paused = true

	for wp in waypoints:
		var target: Vector2 = wp
		var dir := global_position.direction_to(target)
		var distance := global_position.distance_to(target)
		update_direction(dir)

		if distance < 1.0:
			continue

		var duration := distance / spd
		play_animation("run" if spd > 100 else "move")

		if _story_tween and _story_tween.is_valid():
			_story_tween.kill()
		_story_tween = create_tween()
		_story_tween.tween_property(self, "global_position", target, duration)
		await _story_tween.finished

	_in_story_movement = false
	if not _is_interacting:
		_movement_paused = false
	elif Refs.player:
		face_target(Refs.player)
	play_animation("idle")

#endregion


#region ── 导航 & 移动 ─────────────────────────────────────────────────────────

# 在导航网格中选取一个可达位置作为新目标
# 如果设置了 movement_radius > 0, 则只从以 movement_center 为圆心、半径 radius 的范围内选取
func set_new_target() -> void:
	if not _nav_map:
		return

	_stuck_timer = 0.0
	_last_stuck_check_pos = global_position

	var all_cells: Array[Vector2i] = _nav_map.get_used_cells()
	if all_cells.is_empty():
		return

	# 有范围限制时: 预处理所有符合范围的格子, 从过滤池中随机选择
	if movement_radius > 0.0:
		var radius_sq := movement_radius * movement_radius     # 用平方比较, 省去开方
		var in_range: Array[Vector2i] = []
		for cell in all_cells:
			var world_pos := _nav_map.to_global(_nav_map.map_to_local(cell))
			if world_pos.distance_squared_to(movement_center) <= radius_sq:
				in_range.append(cell)
		if in_range.is_empty():
			print("NPC %s: 活动范围内无导航格子, 回退到出生点" % name)
			nav_agent.target_position = movement_center
			return
		var random_cell: Vector2i = in_range.pick_random()
		nav_agent.target_position = _nav_map.to_global(_nav_map.map_to_local(random_cell))
		return

	# 无范围限制: 从全部导航格子中随机选择
	var random_cell: Vector2i = all_cells.pick_random()
	nav_agent.target_position = _nav_map.to_global(_nav_map.map_to_local(random_cell))


# Timer 节点超时 → 目标处等待结束, 选取新目标继续游走
func _on_timer_timeout() -> void:
	set_new_target()


# 是否正在目标点等待 ( timer 未到期 )
func is_waiting_for_next_move() -> bool:
	return not timer.is_stopped()


# 是否已到达导航目标位置
func has_reached_target() -> bool:
	return nav_agent.is_navigation_finished()

#endregion


#region ── 动画 & 朝向 ─────────────────────────────────────────────────────────

# 从 AnimatedSprite2D 当前动画中提取初始朝向 (如 "idle_up" → "up")
func _detect_initial_direction() -> void:
	var anim := anim_sprite.animation
	for dir in ["up", "down", "left", "right"]:
		if anim.ends_with("_" + dir):
			last_direction = dir
			return

# 播放方向相关动画, 格式: 动作_朝向 ( 如 "move_down" / "idle_left" )
func play_animation(anim: String) -> void:
	anim_sprite.play("%s_%s" % [anim, last_direction])


# 根据移动方向向量更新 last_direction ( 八方向取主要分量 )
func update_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		last_direction = "right" if dir.x > 0 else "left"
	else:
		last_direction = "down" if dir.y > 0 else "up"


# 即刻面向指定节点 ( 剧情移动结束时自动调用 )
func face_target(target: Node2D) -> void:
	if not target:
		return
	var dir := global_position.direction_to(target.global_position)
	update_direction(dir)
	play_animation("idle")

#endregion
