extends Control

@onready var start_button = $MainContainer/ButtonsContainer/start/StartButton
@onready var exit_button = $MainContainer/ButtonsContainer/exit/ExitButton


@onready var back_button: Button = $BackButton
@onready var pre_button: Button = $prepare/pre_Button
@onready var prepare_1: Sprite2D = $prepare1
@onready var press_audio_player: AudioStreamPlayer = $PressAudioPlayer


# 加载音效资源（只需要声明一次）
var press1_sound: AudioStream
var press2_sound: AudioStream  # 这个实际上在GameScene中使用
var is_prepare_visible: bool = false

func _ready():
	# 加载音效文件
	press1_sound = load("res://Microgame/Games/shared/assets/audio/press1.wav")
	
	# 连接所有按钮的pressed信号到音效
	_connect_buttons_sound()
	
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	back_button.pressed.connect(_on_back_pressed)
	pre_button.pressed.connect(_on_pre_pressed)
	

func _connect_buttons_sound():
	# 为所有按钮连接音效（注意：不要重复连接）
	var all_buttons = [
		start_button, exit_button, back_button, pre_button
	]
	for button in all_buttons:
		if button and not button.pressed.is_connected(_play_press_sound):
			button.pressed.connect(_play_press_sound)

func _play_press_sound():
	if press_audio_player and press1_sound:
		press_audio_player.stream = press1_sound
		press_audio_player.play()

func _on_start_pressed():
	# 直接开始游戏（使用map关卡）
	MicroGameManage.switch_game(MicroGameManage.GameType.PUZZLE_MAP)
	MicroGameManage.set_difficulty(MicroGameManage.Difficulty.MAP)
	print("开始游戏 - 使用map关卡")
	
	# 延迟一点加载，让用户看到选择反馈
	await get_tree().create_timer(0.2).timeout
	MicroGameManage.start_game()
	
func _on_back_pressed():
	back_button.visible = false
	print("返回主菜单")

func _on_exit_pressed():
	get_tree().quit()	

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
