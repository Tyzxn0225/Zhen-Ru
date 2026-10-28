extends Control

@onready var get_node: AnimatedSprite2D = $get  
@onready var back_button: Button = $BackButton
@onready var audio_player: AudioStreamPlayer = $AudioPlayer

func _ready():
	# 场景加载后自动播放get节点动画
	if get_node:
		get_node.play()
		print("播放get节点动画")
	
	# 连接返回按钮
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	# 返回原始场景
	await Transition.fade_in(0.3)
	# MicroGameManage 使用 change_scene_to_file 加载了此场景，绕过了 LongSceneManager，
	# 导致 LongSceneManager 的 current_scene 仍指向已释放的 StartMenu2。
	# 必须先同步 LongSceneManager 的追踪状态，否则本场景不会被正确移除。
	LongSceneManager.current_scene = get_tree().current_scene
	LongSceneManager.current_scene_path = scene_file_path
	# 不需要调用 GameData.restore_player_data —— player 在自己的 _ready() 中会自行恢复
	LongSceneManager.switch_scene(GameData.return_scene, LongSceneManager.LoadMethod.BOTH_PRELOAD_FIRST, false, "no_transition")
	if get_tree():
		await get_tree().process_frame
	Transition.fade_out(0.3)
