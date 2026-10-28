extends CanvasLayer
class_name  HUD

@onready var shop_panel: ShopPanel = $ShopPanel



@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = %HealthLabel

@onready var mana_bar: ProgressBar = $ManaBar
@onready var mana_label: Label = %ManaLabel

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var stamina_label: Label = %StaminaLabel

@onready var coin_label: Label = $HBoxCoin/Label
@onready var point_label: Label = $HBoxPoint/PointLabel

@onready var exp_bar: ProgressBar = $ExpBar

#region ── Mini Map（已移至 MainButtons，此处保留兼容） ───────────────────────

@export var zoomed_map_size: float = 800.0
@export var mini_map_zoom: float = 0.5
@export var zoomed_map_camera_zoom: float = 0.35

var mini_map: PanelContainer = null
var mini_map_margin: MarginContainer = null
var mini_map_subviewport: SubViewport = null

var _is_map_zoomed: bool = false
var _original_anchors: Dictionary = {}
var _original_offsets: Dictionary = {}
var _mini_map_button: Button = null

#endregion


func _ready() -> void:
	if not EventBus.on_player_health_updated.is_connected(_on_player_health_updated):
		EventBus.on_player_health_updated.connect(_on_player_health_updated)
	if not EventBus.on_player_mana_updated.is_connected(_on_player_mana_updated):
		EventBus.on_player_mana_updated.connect(_on_player_mana_updated)
	if not EventBus.on_player_new_level.is_connected(_on_player_new_level):
		EventBus.on_player_new_level.connect(_on_player_new_level)
	if not EventBus.on_player_stamina_updated.is_connected(_on_player_stamina_updated):
		EventBus.on_player_stamina_updated.connect(_on_player_stamina_updated)
	if not EventBus.coin_picked.is_connected(_on_coin_updated):
		EventBus.coin_picked.connect(_on_coin_updated)
	_update_coin_display()

	if not EventBus.campus_points_changed.is_connected(_on_campus_points_updated):
		EventBus.campus_points_changed.connect(_on_campus_points_updated)
	_update_campus_points_display()

	_bind_mini_map_if_present()
	_connect_quest_tracker()


#region ── 任务栏框（预留） ───────────────────────────────────────────────────

func _connect_quest_tracker() -> void:
	if not EventBus.任务已接取.is_connected(refresh_quest_tracker):
		EventBus.任务已接取.connect(refresh_quest_tracker)
	if not EventBus.任务阶段变化.is_connected(_on_quest_tracker_changed):
		EventBus.任务阶段变化.connect(_on_quest_tracker_changed)
	if not EventBus.任务已完成.is_connected(refresh_quest_tracker):
		EventBus.任务已完成.connect(refresh_quest_tracker)
	if not EventBus.任务关注变化.is_connected(refresh_quest_tracker):
		EventBus.任务关注变化.connect(refresh_quest_tracker)


func _on_quest_tracker_changed(_任务ID: String, _阶段: int) -> void:
	refresh_quest_tracker()


## 兼容旧 HUD 节点；实际显示在 MainButtons 的 QuestHint
func refresh_quest_tracker() -> void:
	if UIManager.main_buttons and UIManager.main_buttons.has_method("refresh_quest_hint"):
		UIManager.main_buttons.refresh_quest_hint()
		return
	var tracker_label: Label = find_child("QuestTrackerLabel", true, false) as Label
	if not tracker_label:
		return
	var hint := QuestSystem.获取关注阶段目标()
	tracker_label.text = hint
	tracker_label.visible = not hint.is_empty()


#endregion


#region ── Mini Map（已移至 MainButtons，此处保留兼容） ───────────────────────

func _bind_mini_map_if_present() -> void:
	mini_map = get_node_or_null("MINI MAP") as PanelContainer
	if mini_map == null:
		return
	mini_map_margin = mini_map.get_node_or_null("MarginContainer") as MarginContainer
	mini_map_subviewport = mini_map.get_node_or_null(
		"MarginContainer/SubViewportContainer/SubViewport"
	) as SubViewport
	_setup_mini_map()


func show_mini_map() -> void:
	if GameData.player_is_indoor:
		return
	if mini_map == null and UIManager.main_buttons:
		UIManager.main_buttons.show_mini_map()
		return
	if mini_map:
		mini_map.visible = true
		if not mini_map.get_node_or_null("MiniMapClickOverlay"):
			_setup_mini_map()


func hide_mini_map() -> void:
	if UIManager.main_buttons and UIManager.main_buttons.has_method("hide_mini_map"):
		UIManager.main_buttons.hide_mini_map()
		return
	if mini_map:
		mini_map.visible = false


func _setup_mini_map() -> void:
	if not mini_map:
		return

	_original_anchors = {
		"left": mini_map.anchor_left,
		"right": mini_map.anchor_right,
		"top": mini_map.anchor_top,
		"bottom": mini_map.anchor_bottom,
	}
	_original_offsets = {
		"left": mini_map.offset_left,
		"right": mini_map.offset_right,
		"top": mini_map.offset_top,
		"bottom": mini_map.offset_bottom,
	}

	if mini_map_margin:
		mini_map_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if mini_map.get_node_or_null("MiniMapClickOverlay"):
		return

	_mini_map_button = Button.new()
	_mini_map_button.name = "MiniMapClickOverlay"
	_mini_map_button.flat = true
	_mini_map_button.anchors_preset = Control.PRESET_FULL_RECT
	_mini_map_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var empty := StyleBoxEmpty.new()
	_mini_map_button.add_theme_stylebox_override("normal", empty)
	_mini_map_button.add_theme_stylebox_override("hover", empty)
	_mini_map_button.add_theme_stylebox_override("pressed", empty)
	_mini_map_button.add_theme_stylebox_override("focus", empty)
	_mini_map_button.pressed.connect(_toggle_mini_map)
	mini_map.add_child(_mini_map_button)


func _toggle_mini_map() -> void:
	if mini_map == null:
		return
	_is_map_zoomed = not _is_map_zoomed

	if _is_map_zoomed:
		mini_map.anchor_left = 0.5
		mini_map.anchor_right = 0.5
		mini_map.anchor_top = 0.5
		mini_map.anchor_bottom = 0.5
		var half := zoomed_map_size / 2.0
		mini_map.offset_left = -half
		mini_map.offset_top = -half
		mini_map.offset_right = half
		mini_map.offset_bottom = half
		var cam := mini_map_subviewport.get_node_or_null("Camera2D") as Camera2D if mini_map_subviewport else null
		if cam:
			cam.zoom = Vector2(zoomed_map_camera_zoom, zoomed_map_camera_zoom)
	else:
		mini_map.anchor_left = _original_anchors["left"]
		mini_map.anchor_right = _original_anchors["right"]
		mini_map.anchor_top = _original_anchors["top"]
		mini_map.anchor_bottom = _original_anchors["bottom"]
		mini_map.offset_left = _original_offsets["left"]
		mini_map.offset_right = _original_offsets["right"]
		mini_map.offset_top = _original_offsets["top"]
		mini_map.offset_bottom = _original_offsets["bottom"]
		var cam := mini_map_subviewport.get_node_or_null("Camera2D") as Camera2D if mini_map_subviewport else null
		if cam:
			cam.zoom = Vector2(mini_map_zoom, mini_map_zoom)

#endregion


func open_npc_panel(type:NPC.NpcType)->void:
	match type:
		NPC.NpcType.SHOP:
			shop_panel.show()
	
func _on_player_health_updated(curr: float, max: float) -> void:
#当玩家生命值变化时被触发（由 EventBus.on_player_health_updated 信号连接）。
	health_bar.value = curr / max
	#health_bar 是一个 ProgressBar 节点。其 value 属性期望一个 0.0 到 1.0 之间的值。
	#curr / max 计算出当前生命比例（例如 75/100 = 0.75），进度条就会显示 75% 填充。
	health_label.text = "%d / %d" % [curr, max]
	#使用 GDScript 的字符串格式化：%d 表示整数占位符。
	#[curr, max] 数组依次替换两个 %d。最终显示类似 "75 / 100"。

func _on_player_mana_updated(curr: float, max: float) -> void:
	mana_bar.value = curr / max
	mana_label.text = "%d / %d" % [curr, max]

func _on_player_new_level(curr: float, new_level: float) -> void:
	exp_bar.value = curr / new_level

func _on_player_stamina_updated(curr: float, max_val: float) -> void:
	stamina_bar.value = curr / max_val
	stamina_label.text = "%d / %d" % [curr, max_val]

func _on_coin_updated() -> void:
	_update_coin_display()

func _update_coin_display() -> void:
	coin_label.text = str(GameData.coins)


func _on_campus_points_updated() -> void:
	_update_campus_points_display()

func _update_campus_points_display() -> void:
	point_label.text = str(GameData.campus_points)
