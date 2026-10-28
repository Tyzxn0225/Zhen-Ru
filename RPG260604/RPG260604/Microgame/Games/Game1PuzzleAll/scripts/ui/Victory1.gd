extends Control

@onready var auto_timer = $Timer
@onready var back_button: Button = $BackButton
@onready var press_audio_player: AudioStreamPlayer = $BackButton/PressAudioPlayer


func _ready():
	back_button.pressed.connect(_on_back_pressed)
	back_button.pressed.connect(_play_button_sound) 

func _play_button_sound():
	if press_audio_player:
		press_audio_player.play()

func _on_back_pressed():
	# 先播放音效，等待一小段时间后再切换场景
	_play_button_sound()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Microgame/Games/Game1PuzzleAll/scenes/ui/StartMenu1.tscn")


func _on_timer_timeout() -> void:
	print("胜利场景已加载！")
	# 3秒后自动返回
	await get_tree().create_timer(3.0).timeout  # 注意：3.0 不是 3,0
	get_tree().change_scene_to_file("res://Microgame/Games/Game1PuzzleAll/scenes/ui/Victory1.tscn")
	
func _on_auto_return_timer_timeout():
	get_tree().change_scene_to_file("res://Microgame/Games/Game1PuzzleAll/scenes/ui/StartMenu1.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Microgame/Games/Game1PuzzleAll/scenes/ui/StartMenu1.tscn")
