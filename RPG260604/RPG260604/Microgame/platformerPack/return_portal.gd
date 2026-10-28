extends Area2D
class_name ReturnPortal

@export var fade_in_speed :float = 1.0
@export var fade_out_speed :float = 1.0

@export var target_pos: Node2D

# ==================== 场景间跳转设置 ====================
@export var enable_cross_scene: bool = false
@export var target_scene_path: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	#if not body.is_in_group("Player"):
		#return

	if GameData.return_scene.is_empty():
		print("ReturnPortal: 没有记录要返回的场景")
		return
	if not ResourceLoader.exists(GameData.return_scene):
		print("ReturnPortal: 要返回的场景不存在: ", GameData.return_scene)
		return

	print("ReturnPortal: 开始返回场景: ", GameData.return_scene)
	await Transition.fade_in(fade_in_speed)
	GameData.restore_player_data(body)
	
	LongSceneManager.switch_scene(GameData.return_scene, LongSceneManager.LoadMethod.BOTH_PRELOAD_FIRST, true, "no_transition")
	if get_tree():
		await get_tree().process_frame
	Transition.fade_out(fade_out_speed)
