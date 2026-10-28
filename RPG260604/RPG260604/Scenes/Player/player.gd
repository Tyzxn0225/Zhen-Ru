extends CharacterBody2D
class_name Player


# ==============================================================================
# 交互协议 (Protocol) — 可交互对象需实现以下方法才能被本系统识别：
#   get_interact_name() -> String      返回交互对象显示名
#   get_interact_action() -> String    返回动作描述 ( "对话" / "传送" / "交易" 等 )
#   get_interact_priority() -> int     返回优先级 ( 越大越靠前, 同名按距离排序 )
#   interact(player: Player) -> void   执行交互逻辑
# ==============================================================================


#region ── 导出变量 ───────────────────────────────────────────────────────────

@export_group("States")
@export var max_health: float = 10.0
@export var max_mana: float = 10.0
@export var move_speed: float = 100.0
@export var run_multiplier: float = 2           # 跑步移速倍率
@export var damage: float = 5.0
@export var crit_chance: float = 0.0
@export var crit_damage: float = 0.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_consume_rate: float = 10.0   # 跑步时每秒消耗
@export var stamina_recover_rate: float = 1.0    # 非跑步时每秒恢复

@export_group("Exp")
@export var base_exp: float = 100               # 升级基础经验
@export var exp_multiplier: float = 2           # 每级经验倍率 ( 公式: next = base * multiplier^level )

@export_group("Interaction")
@export var interaction_key_label: String = "[E]"  # 提示键名, 可在 Inspector 中改成 "[F]" 等

#endregion


#region ── 场景节点引用 ────────────────────────────────────────────────────────
@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
@onready var fsm: FSM = $FSM                     # 有限状态机, 管理 idle/walk/attack 状态
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var enemy_area: Area2D = %EnemyAttrackArea  # 武器攻击检测区
@onready var weapon: Node2D = $weapon

@onready var attack_positions: Dictionary = {    # 攻击判定 Marker 位置 ( 按朝向索引 )
	"down":  %down,
	"left":  %left,
	"right": %right,
	"up":    %up,
}

# 交互系统 — 检测区节点 ( Player 自带 )
@onready var interaction_area: Area2D = $InteractionArea

# 交互系统 — 世界空间提示由 UIManager 运行时管理 InteractMarker

#endregion


#region ── 运行时状态变量 ──────────────────────────────────────────────────────

# 经验 & 等级
var curr_exp: float
var next_level_exp: float
var curr_level: int = 1
var curr_points: int = 0

# 法力
var curr_mana: float

# 朝向 ( 上一次移动方向 ), 用于播放 "walk_down" / "idle_up" 等动画
var last_direction: String = "left"

# 输入拦截标志 — 对话框打开 / 剧情演出时阻止移动和交互
var is_input_blocked: bool = false

# 体力系统 — Walk 状态写入: 当前帧是否实际处于跑步中 (速度 > walk)
var _is_running_active: bool = false

#endregion


#region ── 交互系统内部状态 ────────────────────────────────────────────────────

# 当前碰撞检测范围内所有实现了交互协议的对象
var interactables_in_range: Array[Node] = []

# 当前选中的交互对象在列表中的索引, -1 表示无选中
var current_interact_index: int = -1

# Tab / 滚轮手动切换后为 true, 排序变化时保持同一对象; 否则始终跟随排序后的首选目标
var _interact_target_locked: bool = false

# 自定义提示状态已移至 UIManager ( 通过 UIManager.custom_hint_active 访问 )

#endregion


#region ── 生命周期 ────────────────────────────────────────────────────────────

func _ready() -> void:
	stamina_component.on_stamina_changed.connect(_on_stamina_changed)
	setup()
	Refs.player = self
	add_to_group("player")
	GameData.restore_player_data(self)
	EventBus.on_dialogue_input_blocked.connect(_on_dialogue_input_blocked)
	EventBus.player_story_move_request.connect(_on_player_story_move_request)
	UIManager.custom_hint_hidden.connect(_reconcile_interact_selection)
	# 延迟一帧发射体力初始值, 确保 HUD 已连接信号
	call_deferred("emit_initial_stamina")
	print("Player: Ready, registered in Refs and 'player' group")


# Godot 输入回调 — 处理按键, 优先级高于 _process
# 注意: get_tree().paused 不会阻止 _input(), 需要手动检查
func _input(event: InputEvent) -> void:
	if PauseManager.is_paused:
		return

	# 调试热键: 扣血扣蓝
	if event.is_action_pressed("debug_damage"):
		use_mana(2)
		health_component.take_damage(3)
		print("Debug: Health -3, Mana -2")
		return

	# 对话框打开时拦截所有交互键s
	if is_input_blocked:
		return

	# 按交互键 → 对当前选中的对象执行交互
	if event.is_action_pressed("interact"):
		_interact_with_current()

	# 按切换键 → 在多交互对象间循环选择 ( 吞掉 Tab, 避免 MainButtons 抢焦点 )
	if event.is_action_pressed("switch_interact_target"):
		get_viewport().set_input_as_handled()
		_cycle_interact_target(1)

	# 滚轮 → 在多交互对象间切换 (上滚上一个 / 下滚下一个)
	if interactables_in_range.size() > 1 and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_interact_target(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_interact_target(1)


# 每帧更新: 1) 体力消耗/恢复  2) 状态机逻辑  3) 交互对象列表刷新
func _process(delta: float) -> void:
	_update_stamina(delta)

	if is_input_blocked:
		return

	if fsm.curr_state:
		fsm.curr_state.process_state(delta)

	_refresh_interactables()

#endregion


#region ── 对话框输入拦截 ──────────────────────────────────────────────────────

# 当对话系统打开/关闭时 EventBus 会广播此信号
func _on_dialogue_input_blocked(is_blocked: bool) -> void:
	is_input_blocked = is_blocked
	if is_blocked:
		velocity = Vector2.ZERO
		UIManager.set_interaction_hints_suppressed(true)
		print("Player: Input blocked by dialogue, stopping movement")
	else:
		UIManager.set_interaction_hints_suppressed(false)
		refresh_interaction_hints()
		print("Player: Input unblocked, controls restored")

#endregion


#region ── 交互检测入口 ────────────────────────────────────────────────────────

# InteractionArea 的信号回调 — 4 个信号均由 .tscn 连接
# body  → CharacterBody2D 类型 ( NPC )
# area  → Area2D 类型       ( Portal / TutorialZone 等 )

func _on_interact_body_entered(body: Node) -> void:
	_add_interactable(body)

func _on_interact_body_exited(body: Node) -> void:
	_remove_interactable(body)

func _on_interact_area_entered(area: Area2D) -> void:
	_add_interactable(area)

func _on_interact_area_exited(area: Area2D) -> void:
	_remove_interactable(area)

#endregion


#region ── 交互列表管理 ────────────────────────────────────────────────────────

# 将节点加入交互候选列表, 自动排序并刷新提示
func _add_interactable(node: Node) -> void:
	if not Interactable.is_interactable(node):
		return
	if interactables_in_range.has(node):
		return
	interactables_in_range.append(node)
	_interact_target_locked = false
	_reconcile_interact_selection()


# 将节点从候选列表中移除, 并维护 current_interact_index 的合法性
func _remove_interactable(node: Node) -> void:
	if not interactables_in_range.has(node):
		return
	interactables_in_range.erase(node)
	if interactables_in_range.is_empty():
		_interact_target_locked = false
	_reconcile_interact_selection()


# 按优先级 + 距离排序: 优先级高的在前, 同名按与 Player 的距离升序
func _sort_interactables() -> void:
	interactables_in_range.sort_custom(func(a, b):
		var pa = Interactable.get_obj_priority(a)
		var pb = Interactable.get_obj_priority(b)
		if pa != pb:
			return pa > pb
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)


# 每帧调用: 根据 InteractionArea 当前重叠对象同步列表 ( 不仅依赖 enter/exit 信号 )
func _refresh_interactables() -> void:
	_sync_interaction_overlaps()


## 对话结束 / 自定义屏幕提示关闭后, 重新扫描交互区并刷新世界空间标记
func refresh_interaction_hints() -> void:
	_sync_interaction_overlaps()
	call_deferred("_sync_interaction_overlaps")


## 扫描交互区内现有重叠对象, 同步 interactables_in_range 并刷新提示
func _sync_interaction_overlaps() -> void:
	if not interaction_area:
		return

	var overlapping: Array[Node] = []
	for body in interaction_area.get_overlapping_bodies():
		if Interactable.is_interactable(body):
			overlapping.append(body)
	for area in interaction_area.get_overlapping_areas():
		if Interactable.is_interactable(area):
			overlapping.append(area)

	var i: int = interactables_in_range.size() - 1
	while i >= 0:
		var node := interactables_in_range[i]
		if not is_instance_valid(node) or not Interactable.is_interactable(node) or not overlapping.has(node):
			interactables_in_range.remove_at(i)
		i -= 1

	for node in overlapping:
		if interactables_in_range.has(node):
			continue
		interactables_in_range.append(node)
		_interact_target_locked = false

	_reconcile_interact_selection()


func _get_current_interactable() -> Node:
	if current_interact_index < 0 or current_interact_index >= interactables_in_range.size():
		return null
	return interactables_in_range[current_interact_index]


# 排序后同步选中索引与世界空间提示 ( 解决列表重排后描边与 E 键目标不一致 )
func _reconcile_interact_selection() -> void:
	var locked_target: Node = null
	if _interact_target_locked and current_interact_index >= 0:
		locked_target = _get_current_interactable()

	_sort_interactables()

	if interactables_in_range.is_empty():
		_select_interactable(-1)
		return

	if current_interact_index < 0:
		_select_interactable(0)
		return

	if _interact_target_locked:
		if locked_target and interactables_in_range.has(locked_target):
			current_interact_index = interactables_in_range.find(locked_target)
			_update_interaction_hints()
		else:
			_interact_target_locked = false
			_select_interactable(0)
		return

	current_interact_index = 0
	_update_interaction_hints()

#endregion


#region ── 交互提示刷新 ────────────────────────────────────────────────────────

# 切换当前选中对象并刷新世界空间 InteractMarker
func _select_interactable(index: int) -> void:
	current_interact_index = index
	if index < 0:
		_interact_target_locked = false
	_update_interaction_hints()


# 将当前范围内对象同步到 UIManager, 由其在对象上显示/高亮 InteractMarker
func _update_interaction_hints() -> void:
	UIManager.update_interaction_hints(interactables_in_range, current_interact_index)

#endregion


#region ── 交互执行 ────────────────────────────────────────────────────────────

# 玩家按 E 键 → 对当前选中对象调用 interact()
# 执行前自动转向目标 ( 朝向由交互对象的方位决定, 不恢复 )
func _interact_with_current() -> void:
	if current_interact_index < 0 or current_interact_index >= interactables_in_range.size():
		return

	var target := interactables_in_range[current_interact_index]
	if not is_instance_valid(target) or not Interactable.is_interactable(target):
		_refresh_interactables()
		return

	# 转向目标对象 ( Portal 不改变朝向, 传送后方向无意义 )
	var previous_direction := last_direction
	var dir := global_position.direction_to(target.global_position)
	update_direction(dir)
	play_direction_anim("idle")

	Interactable.execute(target, self)

	# Portal 传送后恢复交互前的朝向
	if target is Portal:
		last_direction = previous_direction
		play_direction_anim("idle")


# 玩家按 Tab / 滚轮 → 在多个可交互对象之间切换
# direction: 1 = 下一个, -1 = 上一个
func _cycle_interact_target(direction: int = 1) -> void:
	if interactables_in_range.size() <= 1:
		return
	_interact_target_locked = true
	var count := interactables_in_range.size()
	var next := (current_interact_index + direction) % count
	if next < 0:
		next += count
	_select_interactable(next)

#endregion


#region ── 移动 & 方向 ─────────────────────────────────────────────────────────

# 被 FSM Walk 状态调用, 判断玩家是否正在按移动键
func is_moving() -> bool:
	var move_input = ["move_down", "move_up", "move_left", "move_right"]
	for input in move_input:
		if Input.is_action_pressed(input):
			return true
	return false


# 根据输入向量更新 last_direction ( 八方向取主要分量 )
# 被 FSM Walk 状态调用
func update_direction(input_vector: Vector2) -> void:
	if input_vector == Vector2.ZERO:
		return
	if abs(input_vector.x) > abs(input_vector.y):
		last_direction = "right" if input_vector.x > 0 else "left"
	else:
		last_direction = "down" if input_vector.y > 0 else "up"


# 播放方向相关动画, 命名格式: 动作_朝向 ( 如 "walk_down" )
# 被 FSM 各状态调用
func play_direction_anim(anim_name: String) -> void:
	print("播放动画: ", anim_name, "_", last_direction)
	anim_sprite.play("%s_%s" % [anim_name, last_direction])


# 开启/关闭武器检测区 ( 被 FSM Attack 状态调用 )
func enable_weapon_collision(value: bool) -> void:
	enemy_area.monitorable = value


# 即刻面向指定节点 ( 剧情移动后自动使用 )
func face_target(target: Node2D) -> void:
	if not target:
		return
	var dir := global_position.direction_to(target.global_position)
	update_direction(dir)
	play_direction_anim("idle")


func teleport_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	play_direction_anim("idle")

#endregion


#region ── 剧情移动 ( Story Movement ) ─────────────────────────────────────────
# 用于剧情演出中控制玩家移动
# 即发即忘版 ( -> void ) 适合 dialogue 的 do ; 阻塞版适合 DM await
# 移动结束后自动面向当前 NPC

signal player_story_move_finished


var _story_tween: Tween
var _story_moving: bool = false


# 响应 EventBus 剧情移动事件 — 由 dialogue do 通过事件驱动调用
func _on_player_story_move_request(waypoints: Array, speed: float) -> void:
	story_move_waypoints(waypoints, speed)


# 单点剧情移动 ( 即发即忘, 故事 NPC 配合用 )
func story_move_to(target: Vector2, speed: float = 80.0) -> void:
	_story_moving = true
	_do_single_move(target, speed)


func _do_single_move(target: Vector2, speed: float):
	await _chain_story_move(target, speed)
	_finish_story_move()


# 多点航点移动
func story_move_waypoints(waypoints: Array, speed: float = 80.0) -> void:
	_story_moving = true
	_do_waypoints(waypoints, speed)


func _do_waypoints(waypoints: Array, speed: float):
	for wp in waypoints:
		await _chain_story_move(wp, speed)
	_finish_story_move()


# 移动完成收尾: 对话中面向 NPC, 否则保持 idle
func _finish_story_move() -> void:
	if is_input_blocked and Refs.current_npc:
		face_target(Refs.current_npc)
	_story_moving = false
	player_story_move_finished.emit()


# 核心: tween 移动 + 方向动画
func _chain_story_move(target: Vector2, speed: float):
	var dir := global_position.direction_to(target)
	var distance := global_position.distance_to(target)

	update_direction(dir)

	if distance < 1.0:
		play_direction_anim("idle")
		return

	var duration: float = distance / speed
	play_direction_anim("run" if speed > 100 else "move")

	_story_tween = create_tween()
	_story_tween.tween_property(self, "global_position", target, duration)
	await _story_tween.finished

	play_direction_anim("idle")


# 中途强制停止剧情移动
func stop_story_move() -> void:
	_story_moving = false
	if _story_tween and _story_tween.is_valid():
		_story_tween.kill()
	play_direction_anim("idle")


# 等待当前剧情移动完成 ( DM 阻塞用 )
func wait_for_move():
	while _story_moving:
		await get_tree().process_frame


# 单点移动 ( DM 等待, 移动完成后面向 NPC )
func story_move_blocking(target: Vector2, speed: float = 80.0):
	var dir := global_position.direction_to(target)
	var distance := global_position.distance_to(target)
	update_direction(dir)

	if distance < 1.0:
		play_direction_anim("idle")
		player_story_move_finished.emit()
		return

	var duration: float = distance / speed
	play_direction_anim("run" if speed > 100 else "move")

	_story_tween = create_tween()
	_story_tween.tween_property(self, "global_position", target, duration)
	await _story_tween.finished

	play_direction_anim("idle")
	if is_input_blocked and Refs.current_npc:
		face_target(Refs.current_npc)
	player_story_move_finished.emit()

#endregion


#region ── 等级 & 经验 ─────────────────────────────────────────────────────────

# 升级: 经验溢出部分保留, 提升等级 + 获得 4 属性点, 更新下阶经验
func level_up() -> void:
	curr_exp -= next_level_exp
	curr_level += 1
	curr_points += 4
	next_level_exp *= exp_multiplier
	EventBus.on_player_stats_updated.emit()


# 获得经验, 连续升级直到经验不足下一阶
func add_exp(value: float) -> void:
	curr_exp += value
	while curr_exp >= next_level_exp:
		level_up()
		EventBus.on_player_new_level.emit(curr_exp, next_level_exp)

#endregion


#region ── 初始化 & 重生 ────────────────────────────────────────────────────────

# 初始化/重生: 重置生命法力 + 计算首级经验
func setup() -> void:
	reset_health()
	reset_mana()
	reset_stamina()
	next_level_exp = base_exp

#endregion


#region ── 生命 & 法力 ─────────────────────────────────────────────────────────

func reset_health() -> void:
	health_component.setup(max_health)
	EventBus.on_player_health_updated.emit(max_health, max_health)


func reset_mana() -> void:
	curr_mana = max_mana
	EventBus.on_player_mana_updated.emit(max_mana, max_mana)


# 消耗法力, 向下 clamp 到 0
func use_mana(value: float) -> void:
	curr_mana -= value
	curr_mana = max(curr_mana, 0)
	EventBus.on_player_mana_updated.emit(curr_mana, max_mana)


# 恢复法力, 向上 clamp 到 max_mana
func add_mana(value: float) -> void:
	curr_mana += value
	curr_mana = min(max_mana, curr_mana)
	EventBus.on_player_mana_updated.emit(curr_mana, max_mana)

#endregion


#region ── 体力系统 ─────────────────────────────────────────────────────────────

# 每帧更新体力: 跑步时消耗, 否则恢复

func _update_stamina(delta: float) -> void:
	# 对话/交互时: 不消耗, 但仍恢复体力
	if is_input_blocked:
		stamina_component.recover(stamina_recover_rate * delta)
		return
	if is_running():
		stamina_component.consume(stamina_consume_rate * delta)
	else:
		stamina_component.recover(stamina_recover_rate * delta)

# ── 查询 ──────────────────────────────────────────────────────────────────────

# 是否正在跑步 (Walk 状态实际应用了跑步速度 + 体力 > 0)
func is_running() -> bool:
	return _is_running_active and stamina_component.curr_stamina > 0

# 体力足够跑步 (供 Walk 状态查询) — 阈值20: 低于20不允许启动跑步, 但已跑步中可消耗到0
func can_run() -> bool:
	return stamina_component.curr_stamina > 20

# 有效跑步倍率: 体力 ≥90% 时满倍率, 20% 时衰减到 50%, 线性插值
func get_effective_run_multiplier() -> float:
	if stamina_component.max_stamina <= 0:
		return run_multiplier
	var ratio := stamina_component.curr_stamina / stamina_component.max_stamina
	# 20%~90% 区间映射到 0.5~1.0
	var scale := lerpf(0.5, 1.0, clampf((ratio - 0.2) / 0.7, 0.0, 1.0))
	return run_multiplier * scale

# ── 公开 API: 物品 / 对话脚本可调用 ────────────────────────────────────────────

## 修改最大体力上限 (物品 / Buff 调用)
func set_max_stamina(value: float) -> void:
	max_stamina = value
	stamina_component.set_max(value)

## 修改跑步消耗速率 (物品 / Buff 调用)
func set_stamina_consume_rate(value: float) -> void:
	stamina_consume_rate = value

## 修改恢复速率 (物品 / Buff 调用)
func set_stamina_recover_rate(value: float) -> void:
	stamina_recover_rate = value

## 直接恢复体力(向上 clamp), 物品调用
func recover_stamina(value: float) -> void:
	stamina_component.recover(value)

# ── 初始化 ────────────────────────────────────────────────────────────────────

func reset_stamina() -> void:
	stamina_component.setup(max_stamina)

func emit_initial_stamina() -> void:
	EventBus.on_player_stamina_updated.emit(stamina_component.curr_stamina, stamina_component.max_stamina)

func _on_stamina_changed(curr: float, max_val: float) -> void:
	EventBus.on_player_stamina_updated.emit(curr, max_val)

#endregion


#region ── 生命组件回调 ────────────────────────────────────────────────────────

func _on_health_component_on_dead() -> void:
	queue_free()


func _on_health_component_on_health_changed(curr_health: float) -> void:
	EventBus.on_player_health_updated.emit(curr_health, max_health)

#endregion


func _on_skills_button_pressed() -> void:
	pass
