# PauseManager (Autoload) — 全局暂停管理器
# 功能: 拦截 ESC 键 → 切换暂停状态 → 实例化/隐藏暂停菜单
# 原理: get_tree().paused = true 冻结所有 process_mode != ALWAYS 的节点
#       pause_menu 自身 process_mode = ALWAYS 所以不受影响

extends Node

const MENU_SCENE := preload("res://Scenes/UI/pause_menu/pause_menu.tscn")

var is_paused: bool = false
var _menu: CanvasLayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS


# _unhandled_input: 只有未被任何 Control 消费的输入才会到达这里
# 对话进行中仍可通过 ESC 暂停; 其他 UI 若消费 ESC 则不会误触暂停
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()


func _toggle() -> void:
	if is_paused:
		resume()
	else:
		pause()


# 暂停: 冻结物理/进程/动画/计时器, 弹出菜单
# 关键顺序: 先实例化菜单入树 (让 _ready() 正常执行), 再暂停场景树
func pause() -> void:
	if is_paused:
		return
	is_paused = true

	if not _menu:
		_menu = MENU_SCENE.instantiate()
		_menu.process_mode = PROCESS_MODE_ALWAYS
		get_tree().root.add_child(_menu)
		await get_tree().process_frame

	_menu.visible = true
	if _menu.has_method("on_open"):
		_menu.on_open()

	get_tree().paused = true
	EventBus.game_paused.emit()


# 恢复: 解除冻结, 隐藏菜单
func resume() -> void:
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false

	if _menu:
		_menu.visible = false

	EventBus.game_resumed.emit()
