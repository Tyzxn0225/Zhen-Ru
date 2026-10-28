extends Control

@onready var begin_1: Button = $Main/Buttons/begin/begin1
@onready var easy_1: Button = $Main/Difficulty/easy/easy1
@onready var normal_1: Button = $Main/Difficulty/normal/normal1
@onready var hard_1: Button = $Main/Difficulty/hard/hard1
@onready var back_button: Button = $BackButton
@onready var pre_button: Button = $prepare1/PreButton
@onready var prepare_2: Sprite2D = $prepare2

# 音效变量
var press1_sound: AudioStream
var is_prepare_visible: bool = false

func _ready():
	# 隐藏难度选择面板
	$Main/Difficulty.visible = false
	back_button.visible = false
	prepare_2.visible = false
	
	# 加载音效
	press1_sound = load("res://Microgame/Games/shared/assets/audio/press1.wav")
	
	# 连接所有按钮的pressed信号
	_connect_button_signals()

func _connect_button_signals():
	begin_1.pressed.connect(_on_begin_1_pressed)
	easy_1.pressed.connect(_on_easy_1_pressed)
	normal_1.pressed.connect(_on_normal_1_pressed)
	hard_1.pressed.connect(_on_hard_1_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	pre_button.pressed.connect(_on_pre_button_pressed)

func _play_press_sound():
	if press1_sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = press1_sound
		add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)
		
func _on_begin_1_pressed():
	_play_press_sound()
	# 点击"开始游戏"后，显示难度选择
	$Main/Buttons.visible = false
	$Main/Difficulty.visible = true
	back_button.visible = true

func _on_easy_1_pressed():
	_play_press_sound()
	MicroGameManage.switch_game(MicroGameManage.GameType.SHOOT)
	MicroGameManage.set_difficulty(MicroGameManage.Difficulty.EASY)
	MicroGameManage.start_game()

func _on_normal_1_pressed():
	_play_press_sound()
	MicroGameManage.switch_game(MicroGameManage.GameType.SHOOT)
	MicroGameManage.set_difficulty(MicroGameManage.Difficulty.NORMAL)
	MicroGameManage.start_game()

func _on_hard_1_pressed():
	_play_press_sound()
	
	MicroGameManage.switch_game(MicroGameManage.GameType.SHOOT)
	MicroGameManage.set_difficulty(MicroGameManage.Difficulty.HARD)
	MicroGameManage.start_game()

func _on_back_button_pressed():
	_play_press_sound()
	# 返回主菜单
	$Main/Buttons.visible = true
	$Main/Difficulty.visible = false
	back_button.visible = false
	
func _on_pre_button_pressed():
	_play_press_sound()
	prepare_2.visible = true
	is_prepare_visible = true
	print("显示 prepare2")

func _input(event: InputEvent):
	# 当 prepare2 显示时，检测鼠标点击
	if is_prepare_visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			prepare_2.visible = false
			is_prepare_visible = false
			print("隐藏 prepare2")
