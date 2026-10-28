extends Control
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
