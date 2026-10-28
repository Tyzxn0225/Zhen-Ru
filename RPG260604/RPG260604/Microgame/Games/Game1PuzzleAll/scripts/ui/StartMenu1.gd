extends Control

@onready var start_button = $MainContainer/ButtonsContainer/start/StartButton
@onready var exit_button = $MainContainer/ButtonsContainer/exit/ExitButton
@onready var difficulty_container = $MainContainer/DifficultyContainer
@onready var easy_button = $MainContainer/DifficultyContainer/easy/EasyButton
@onready var normal_button = $MainContainer/DifficultyContainer/normal/NormalButton
@onready var hard_button = $MainContainer/DifficultyContainer/hard/HardButton
@onready var buttons_container = $MainContainer/ButtonsContainer

@onready var back_button: Button = $BackButton
@onready var pre_button: Button = $prepare/pre_Button
@onready var prepare_1: Sprite2D = $prepare1
@onready var press_audio_player: AudioStreamPlayer = $PressAudioPlayer


# 加载音效资源（只需要声明一次）
var press1_sound: AudioStream
var press2_sound: AudioStream  # 这个实际上在GameScene中使用
var waiting_for_difficulty: bool = false
var is_prepare_visible: bool = false

func _ready():
	# 加载音效文件
	press1_sound = load("res://Microgame/Games/shared/assets/audio/press1.wav")
	
	# 连接所有按钮的pressed信号到音效
	_connect_buttons_sound()
	
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	easy_button.pressed.connect(_on_difficulty_selected.bind(0))
	normal_button.pressed.connect(_on_difficulty_selected.bind(1))
	hard_button.pressed.connect(_on_difficulty_selected.bind(2))
	back_button.pressed.connect(_on_back_pressed)
	pre_button.pressed.connect(_on_pre_pressed)
	
	# 初始状态
	buttons_container.visible = true
	difficulty_container.visible = false
	waiting_for_difficulty = false

func _connect_buttons_sound():
	# 为所有按钮连接音效（注意：不要重复连接）
	var all_buttons = [
		start_button, exit_button, easy_button,
		normal_button, hard_button, back_button, 
		pre_button
	]
	for button in all_buttons:
		if button and not button.pressed.is_connected(_play_press_sound):
			button.pressed.connect(_play_press_sound)

func _play_press_sound():
	if press_audio_player and press1_sound:
		press_audio_player.stream = press1_sound
		press_audio_player.play()

func _on_start_pressed():
	# 隐藏开始和退出按钮
	buttons_container.visible = false
	
	# 显示难度选择和返回按钮
	difficulty_container.visible = true
	back_button.visible = true
	waiting_for_difficulty = true
	
	print("请选择难度")

func _on_exit_pressed():
		# 返回原始场景
	await Transition.fade_in(0.3)
	GameData.restore_player_data(Refs.player)
	LongSceneManager.switch_scene(GameData.return_scene, LongSceneManager.LoadMethod.BOTH_PRELOAD_FIRST, true, "no_transition")
	if get_tree():
		await get_tree().process_frame
	Transition.fade_out(0.3)

func _on_difficulty_selected(difficulty: int):
	if not waiting_for_difficulty:
		return
	
	# 可选：禁用难度按钮防止重复点击
	easy_button.disabled = true
	normal_button.disabled = true
	hard_button.disabled = true
	
	# 设置当前游戏为拼图大挑战
	MicroGameManage.switch_game(MicroGameManage.GameType.PUZZLE_ALL)
	MicroGameManage.set_difficulty(difficulty)
	print("难度已选择: ", difficulty, "，开始加载游戏场景")
		
	# 延迟一点加载，让用户看到选择反馈
	await get_tree().create_timer(0.2).timeout
	MicroGameManage.start_game()

func _on_back_pressed():
	# 隐藏难度选择，返回主菜单
	difficulty_container.visible = false
	buttons_container.visible = true
	back_button.visible = false
	waiting_for_difficulty = false
	
	# 恢复难度按钮
	easy_button.disabled = false
	normal_button.disabled = false
	hard_button.disabled = false
	print("返回主菜单")

func _on_pre_pressed():
	prepare_1.visible = true
	is_prepare_visible = true
	print("显示 prepare1")

func _input(event: InputEvent):
	# 当 prepare1 显示时，检测鼠标点击
	if is_prepare_visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			prepare_1.visible = false
			is_prepare_visible = false
			print("隐藏 prepare1")
