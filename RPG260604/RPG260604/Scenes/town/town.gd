extends Node2D
class_name Town

@export var player_scene: PackedScene
@export var spawn_position: Vector2 = Vector2.ZERO     # 出生点世界坐标, ZERO = 使用 player.tscn 的默认位置

@onready var navigation: TileMapLayer = %Navigation
@onready var hud: HUD = $HUD


func _ready() -> void:
	
	EventBus.on_inventory_used_item.connect(_on_inventory_used_item)
	EventBus.scene_anim_play.connect(_on_scene_anim_play)
	Refs.navigation = navigation
	Refs.hud = hud
	call_deferred("_refresh_quest_markers")

	# Player 通过场景手动放置时，由 player.gd 的 _ready() 自动注册 Refs.player 和 "player" 分组
	# 若需动态创建 Player，取消下面的注释即可：
	# create_player()

	tree_entered.connect(_on_tree_entered)


#region ── 待续对话自动启动 ( 从小游戏返回时触发 ) ─────────────────────────────

func _on_tree_entered() -> void:
	_check_pending_dialogue.call_deferred()


# 检查是否设置了待启动的后半段对话, 有则启动
func _check_pending_dialogue() -> void:
	if GameData.pending_dialogue_resource_path.is_empty():
		return

	var path: String = GameData.pending_dialogue_resource_path
	var title: String = GameData.pending_dialogue_title

	GameData.pending_dialogue_resource_path = ""
	GameData.pending_dialogue_title = ""

	if not ResourceLoader.exists(path):
		return

	var resource: DialogueResource = load(path)
	if not resource:
		return

	await get_tree().process_frame
	DialogueManager.show_dialogue_balloon(resource, title)

#endregion

func _refresh_quest_markers() -> void:
	QuestSystem.刷新地图标记()


func create_player() -> void:
	var player: Player = player_scene.instantiate()

	add_child(player)

	if spawn_position != Vector2.ZERO:
		player.global_position = spawn_position

	player.setup()
	Refs.player = player
	EventBus.on_player_created.emit()

	print("Town: Player spawned at: ", player.global_position)


func _on_inventory_used_item(item:ItemData)->void:
	# 注意：药水和食物的效果已由 ItemEffectHandler 处理
	# 此函数仅用于处理其他类型的物品效果
	if item.id == "map_scrawl":
		_show_mini_map()

func _show_mini_map() -> void:
	if hud and hud.has_method("show_mini_map"):
		hud.show_mini_map()
	elif UIManager.main_buttons and UIManager.main_buttons.has_method("show_mini_map"):
		UIManager.main_buttons.show_mini_map()


# 响应 EventBus 场景动画请求 — 在当前场景中按名称查找 AnimatedSprite2D 并播放动画
func _on_scene_anim_play(node_name: String, anim: String) -> void:
	var node := find_child(node_name, true, false)
	if node and node is AnimatedSprite2D:
		node.play(anim)
		print("Town: 播放动画 '%s' on '%s'" % [anim, node_name])
	else:
		push_warning("Town: 未找到 AnimatedSprite2D 节点 '%s'" % node_name)
