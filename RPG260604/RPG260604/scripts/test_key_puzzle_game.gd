class_name TestKeyPuzzleGame
extends RefCounted
## 拼图场景：测试键立即胜利。可整文件删除；调用处删 _unhandled_input 即可。


static func try_handle(game_scene: Node, event: InputEvent) -> bool:
	if not TestKey.is_just_pressed(event):
		return false
	if game_scene == null or not is_instance_valid(game_scene):
		return false
	if game_scene.has_method("_game_victory"):
		game_scene.call("_game_victory")
		return true
	return false
