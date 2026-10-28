# MainButtons — 跨场景主按钮栏
# CanvasLayer, process_mode = ALWAYS (不受 get_tree().paused 影响)
# 挂在 get_tree().root 上, 通过 UIManager 管理
# ToastHint / Panels 的位置与大小请在 main_buttons.tscn 检查器中直接调整

extends CanvasLayer

@onready var main_buttons_panel: Panel = %MainButtons
@onready var equipment_button: Button = %EquipmentButton
@onready var inventory_button: Button = %InventoryButton
@onready var stats_button: Button = %StatsButton
@onready var skills_button: Button = %SkillsButton
@onready var quest_button: Button = %QuestButton

@onready var panels_container: HBoxContainer = %Panels
@onready var equipment_panel: Control = %EquipmentPanel
@onready var inventory_panel: Control = %InventoryPanel
@onready var quest_panel: Control = %QuestPanel
@onready var stats_panel: Control = %StatsPanel
@onready var skills_panel: Control = %SkillsPanel

@onready var quest_hint_panel: PanelContainer = %QuestHint
@onready var quest_hint_title: Label = %QuestHintTitleLabel
@onready var quest_hint_detail: Label = %QuestHintDetailLabel
@onready var world_map_panel: PanelContainer = %world_map_panel

var _buttons: Array[Button] = []

const LAYER_NORMAL := 10
const LAYER_ELEVATED := 120

var _dialogue_active: bool = false


func _ready() -> void:
	_buttons = [equipment_button, inventory_button, stats_button, skills_button]
	for button in _buttons:
		if button:
			button.focus_mode = Control.FOCUS_NONE

	_connect_button(equipment_button, _on_equipment_pressed)
	_connect_button(inventory_button, _on_inventory_pressed)
	_connect_button(stats_button, _on_stats_pressed)
	_connect_button(skills_button, _on_skills_pressed)
	_connect_button(quest_button, _on_quest_pressed)
	EventBus.on_dialogue_input_blocked.connect(_on_dialogue_input_blocked)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)

	panels_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bind_mini_map()
	_connect_quest_hint()
	_connect_indoor_minimap()
	call_deferred("refresh_quest_hint")


func _connect_quest_hint() -> void:
	if not EventBus.任务已接取.is_connected(refresh_quest_hint):
		EventBus.任务已接取.connect(refresh_quest_hint)
	if not EventBus.任务阶段变化.is_connected(_on_quest_hint_changed):
		EventBus.任务阶段变化.connect(_on_quest_hint_changed)
	if not EventBus.任务已完成.is_connected(refresh_quest_hint):
		EventBus.任务已完成.connect(refresh_quest_hint)
	if not EventBus.任务关注变化.is_connected(refresh_quest_hint):
		EventBus.任务关注变化.connect(refresh_quest_hint)


func _on_quest_hint_changed(_任务ID: String, _阶段: int) -> void:
	refresh_quest_hint()


func refresh_quest_hint() -> void:
	if quest_hint_panel == null:
		return
	var quest_id := QuestSystem.获取关注任务ID()
	if quest_id.is_empty() or not QuestSystem.是否进行中(quest_id):
		quest_hint_panel.visible = false
		return
	var stage_name := QuestSystem.获取关注阶段名()
	var stage_goal := QuestSystem.获取关注阶段目标()
	if quest_hint_title:
		quest_hint_title.text = stage_name
	if quest_hint_detail:
		quest_hint_detail.text = stage_goal
	quest_hint_panel.visible = not stage_name.is_empty() or not stage_goal.is_empty()


func refresh_quest_panel() -> void:
	if quest_panel and quest_panel.has_method("refresh"):
		quest_panel.call_deferred("refresh")


#region ── Mini Map ───────────────────────────────────────────────────────────

@export var mini_map_zoom: float = 0.5

var mini_map: PanelContainer = null
var mini_map_margin: MarginContainer = null
var mini_map_subviewport: SubViewport = null
var _mini_map_button: Button = null


func _bind_mini_map() -> void:
	mini_map = get_node_or_null("MINI MAP") as PanelContainer
	if mini_map == null:
		return
	mini_map_margin = mini_map.get_node_or_null("MarginContainer") as MarginContainer
	mini_map_subviewport = mini_map.get_node_or_null(
		"MarginContainer/SubViewportContainer/SubViewport"
	) as SubViewport
	var mini_cam := _get_mini_map_camera()
	if mini_cam:
		mini_cam.zoom = Vector2(mini_map_zoom, mini_map_zoom)
	_setup_mini_map()


func _get_mini_map_camera() -> Camera2D:
	if mini_map_subviewport == null:
		return null
	return mini_map_subviewport.get_node_or_null("Camera2D") as Camera2D


func show_mini_map() -> void:
	if mini_map == null:
		return
	if GameData.player_is_indoor:
		return
	mini_map.visible = true
	if not mini_map.get_node_or_null("MiniMapClickOverlay"):
		_setup_mini_map()


func hide_mini_map() -> void:
	if mini_map == null:
		return
	mini_map.visible = false


func _connect_indoor_minimap() -> void:
	if not EventBus.player_indoor_state_changed.is_connected(_on_player_indoor_state_changed):
		EventBus.player_indoor_state_changed.connect(_on_player_indoor_state_changed)
	if GameData.player_is_indoor:
		hide_mini_map()


func _on_player_indoor_state_changed(is_indoor: bool) -> void:
	if is_indoor:
		hide_mini_map()
	else:
		show_mini_map()


func _setup_mini_map() -> void:
	if mini_map == null:
		return

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
	_mini_map_button.pressed.connect(_toggle_world_map)
	mini_map.add_child(_mini_map_button)


func _toggle_world_map() -> void:
	if world_map_panel == null:
		return
	if world_map_panel.visible:
		if world_map_panel.has_method("close"):
			world_map_panel.close()
	elif world_map_panel.has_method("open"):
		world_map_panel.open()


#endregion


func _connect_button(button: Button, callback: Callable) -> void:
	if button:
		button.pressed.connect(callback)


func _on_dialogue_input_blocked(is_blocked: bool) -> void:
	_dialogue_active = is_blocked
	_update_layer()
	UIManager.refresh_main_buttons_visibility()


func _on_game_paused() -> void:
	_update_layer()


func _on_game_resumed() -> void:
	_update_layer()


func _update_layer() -> void:
	layer = LAYER_ELEVATED if PauseManager.is_paused or _dialogue_active else LAYER_NORMAL


func _on_equipment_pressed() -> void:
	_toggle_panel(equipment_panel)


func _on_inventory_pressed() -> void:
	var opened := _toggle_panel(inventory_panel)
	if opened:
		EventBus.on_main_buttons_inventory_opened.emit()


func _on_stats_pressed() -> void:
	_toggle_panel(stats_panel)


func _on_skills_pressed() -> void:
	_toggle_panel(skills_panel)


func _on_quest_pressed() -> void:
	var opened := _toggle_panel(quest_panel)
	if opened and quest_panel.has_method("refresh"):
		quest_panel.refresh()


func _toggle_panel(panel: Control) -> bool:
	_close_all_except(panel)
	panel.visible = not panel.visible
	if panel.visible:
		panels_container.visible = true
	return panel.visible


func _close_all_except(keep: Control) -> void:
	if equipment_panel != keep and equipment_panel.visible:
		equipment_panel.visible = false
	if inventory_panel != keep and inventory_panel.visible:
		inventory_panel.visible = false
	if quest_panel != keep and quest_panel.visible:
		quest_panel.visible = false
	if stats_panel != keep and stats_panel.visible:
		stats_panel.visible = false
	if skills_panel != keep and skills_panel.visible:
		skills_panel.visible = false
