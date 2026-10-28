# pause_menu.gd — 暂停菜单逻辑
# CanvasLayer, process_mode = ALWAYS (不受 get_tree().paused 影响)

extends CanvasLayer


#region ── 节点引用 ────────────────────────────────────────────────────────────

@onready var main_panel: Panel = %MainPanel
@onready var main_vbox: VBoxContainer = %MainVBox

@onready var continue_button: Button = %ContinueButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var exit_button: Button = %ExitButton
@onready var save_status_label: Label = %SaveStatusLabel

# 更改名称面板
var _name_panel: Control
var _name_input: LineEdit

#endregion


#region ── 生命周期 ────────────────────────────────────────────────────────────

func _ready() -> void:
	visible = false

	continue_button.pressed.connect(_on_continue_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	_create_rename_button()
	_create_name_panel()


func _create_rename_button() -> void:
	var rename_button := Button.new()
	rename_button.name = "RenameButton"
	rename_button.custom_minimum_size = Vector2(0, 40)
	rename_button.add_theme_font_size_override("font_size", 48)
	rename_button.text = "更改名称"

	var save_load_hbox := main_vbox.get_node("SaveLoadHBox")
	var save_load_index := save_load_hbox.get_index()
	main_vbox.add_child(rename_button)
	main_vbox.move_child(rename_button, save_load_index)

	rename_button.pressed.connect(_on_rename_pressed)


func _create_name_panel() -> void:
	_name_panel = Control.new()
	_name_panel.name = "NamePanel"
	_name_panel.visible = false
	_name_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_panel.add_child(_name_panel)

	var bg := ColorRect.new()
	bg.name = "NamePanelBg"
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	_name_panel.add_child(bg)

	var center := Panel.new()
	center.name = "CenterPanel"
	center.size = Vector2(600, 280)
	center.position = Vector2(
		(main_panel.size.x - 600) / 2.0,
		(main_panel.size.y - 280) / 2.0
	)
	_name_panel.add_child(center)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	center.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "更改玩家名称"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(title)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer1)

	var hint := Label.new()
	hint.name = "HintLabel"
	hint.text = "请输入新的名称 (2-8个字符)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	vbox.add_child(hint)

	_name_input = LineEdit.new()
	_name_input.name = "NameInput"
	_name_input.custom_minimum_size = Vector2(0, 40)
	_name_input.placeholder_text = "在此输入名称..."
	_name_input.add_theme_font_size_override("font_size", 24)
	_name_input.max_length = 8
	_name_input.text = GameData.player_name
	vbox.add_child(_name_input)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.name = "ButtonHBox"
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)

	var confirm_btn := Button.new()
	confirm_btn.name = "ConfirmButton"
	confirm_btn.custom_minimum_size = Vector2(160, 40)
	confirm_btn.text = "确认"
	confirm_btn.add_theme_font_size_override("font_size", 32)
	confirm_btn.pressed.connect(_on_name_confirm_pressed)
	btn_hbox.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.custom_minimum_size = Vector2(160, 40)
	cancel_btn.text = "取消"
	cancel_btn.add_theme_font_size_override("font_size", 32)
	cancel_btn.pressed.connect(_on_name_cancel_pressed)
	btn_hbox.add_child(cancel_btn)

	var status := Label.new()
	status.name = "NameStatusLabel"
	status.visible = false
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	vbox.add_child(status)


# PauseManager 在弹出菜单时调用, 用于播放进入动画或重置状态
func on_open() -> void:
	main_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.15)
	_hide_name_panel()
	continue_button.grab_focus()

#endregion


#region ── 按钮回调 ────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	PauseManager.resume()


func _on_save_pressed() -> void:
	var player := Refs.player
	if player:
		GameData.save_player_data(player)
	_show_status("存档成功！")


func _on_load_pressed() -> void:
	var player := Refs.player
	if player:
		GameData.restore_player_data(player)
		# 读取存档后恢复生命法力
		player.setup()
		var saved := GameData.player_saved_data
		if player.has_node("HealthComponent") and "current_health" in player.get_node("HealthComponent"):
			player.health_component.current_health = saved.health
		player.curr_mana = saved.mana
		player.curr_exp = saved.experience
		player.curr_level = saved.level
		player.global_position = saved.position
		player.last_direction = saved.direction
		player.play_direction_anim("idle")
		EventBus.on_player_health_updated.emit(saved.health, saved.max_health)
		EventBus.on_player_mana_updated.emit(saved.mana, saved.max_mana)
	_show_status("读档成功！")


func _on_exit_pressed() -> void:
	PauseManager.resume()
	get_tree().paused = false
	if Refs and Refs.player:
		GameData.save_player_data(Refs.player)
	GameData.return_scene = ""
	LongSceneManager.switch_scene("res://Scenes/town.tscn",
		LongSceneManager.LoadMethod.BOTH_PRELOAD_FIRST, false, "no_transition")


func _on_rename_pressed() -> void:
	_name_input.text = GameData.player_name
	_name_input.grab_focus()
	_hide_status()
	_name_panel.visible = true


func _on_name_confirm_pressed() -> void:
	var name := _name_input.text.strip_edges()
	if name.length() < 2:
		_show_name_status("名称至少需要2个字符")
		return
	if name.length() > 8:
		_show_name_status("名称不能超过8个字符")
		return

	GameData.player_name = name
	_hide_name_panel()
	_show_status("名称已更改为: %s" % name)


func _on_name_cancel_pressed() -> void:
	_name_input.text = ""
	_hide_name_panel()


func _hide_name_panel() -> void:
	if _name_panel:
		_name_panel.visible = false


func _show_name_status(text: String) -> void:
	var lbl := _name_panel.get_node("CenterPanel/Margin/VBox/NameStatusLabel") as Label
	if lbl:
		lbl.text = text
		lbl.visible = true

func _hide_status() -> void:
	var lbl := _name_panel.get_node("CenterPanel/Margin/VBox/NameStatusLabel") as Label
	if lbl:
		lbl.visible = false

#endregion


#region ── 辅助 ────────────────────────────────────────────────────────────────

func _show_status(text: String) -> void:
	save_status_label.text = text
	save_status_label.visible = true
	get_tree().create_timer(2.0).timeout.connect(func():
		save_status_label.visible = false
	)

#endregion
