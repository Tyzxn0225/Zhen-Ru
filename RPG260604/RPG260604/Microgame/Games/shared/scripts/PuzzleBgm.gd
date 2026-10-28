extends Node


var bgm_player: AudioStreamPlayer
var current_bgm_path: String = ""

func _ready():
	# 设置为进程内持久化
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 创建 AudioStreamPlayer
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	# 加载并播放 BGM
	play_bgm("res://Microgame/Games/shared/assets/audio/bgm.mp3")

func play_bgm(path: String) -> void:
	if path.is_empty():
		return
	
	if current_bgm_path == path and bgm_player.playing:
		return  # 已经在播放相同的 BGM
	
	current_bgm_path = path
	var stream: AudioStream = load(path)
	if stream:
		stream.loop = true  # 在流对象上设置循环
		bgm_player.stream = stream
		bgm_player.volume_db = -10  # 背景音乐音量调低
		bgm_player.play()
		print("BGM 开始播放: ", path)

func stop_bgm() -> void:
	bgm_player.stop()

func set_volume(db: float) -> void:
	bgm_player.volume_db = db
