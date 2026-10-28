extends Area2D
class_name Portal

@export var target_pos: Node2D

@export var fade_in_speed: float = 0.5
@export var fade_out_speed: float = 0.5

@export var enable_cross_scene: bool = false
@export var target_scene_path: String = ""

#region ── 交互显示自定义 ────────────────────────────────────────────────────

# 留空则自动生成: 跨场景 → 目标场景文件名; 场景内 → "传送点"
@export var portal_name: String = ""

# 留空则自动生成: 跨场景 → "传送"; 场景内 → "进入"
# 自定义示例: "过桥" / "上楼" / "进入副本"
@export var portal_action: String = ""

## 传送完成后将玩家标记为室内（隐藏小地图）
@export var indoor_on_arrival: bool = false
## 传送完成后将玩家标记为室外（恢复小地图）
@export var outdoor_on_arrival: bool = false

#endregion

func _ready() -> void:
	add_to_group("portals")

func get_interact_name() -> String:
	if not portal_name.is_empty():
		return portal_name
	if enable_cross_scene:
		return target_scene_path.get_file().get_basename() if not target_scene_path.is_empty() else "未知场景"
	return "传送点"

func get_interact_action() -> String:
	if not portal_action.is_empty():
		return portal_action
	return "传送" if enable_cross_scene else "进入"

func get_interact_priority() -> int:
	return 5

func interact(player: Player) -> void:
	if not is_instance_valid(player):
		return

	if enable_cross_scene:
		UIManager.switch_scene_with_transition(
			target_scene_path,
			player,           # 传入 player 实例
			"",               # return_scene_path 为空，自动使用当前场景
			fade_in_speed,
			fade_out_speed,
			true              # use_current_as_return = true
		)
	else:
		await Transition.fade_in(fade_in_speed)
		player.global_position = target_pos.global_position
		_apply_arrival_zone()
		Transition.fade_out(fade_out_speed)


func _apply_arrival_zone() -> void:
	if indoor_on_arrival:
		_set_player_indoor(true)
	elif outdoor_on_arrival:
		_set_player_indoor(false)


func _set_player_indoor(indoor: bool) -> void:
	if GameData.player_is_indoor == indoor:
		return
	GameData.player_is_indoor = indoor
	EventBus.player_indoor_state_changed.emit(indoor)
