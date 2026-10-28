class_name TestKeyBoxGame
extends RefCounted
## Box 推箱：测试键立即胜利。可整文件删除；调用处删一行即可恢复原有逻辑。


static func try_handle(game: Node, event: InputEvent) -> bool:
	if not TestKey.is_just_pressed(event):
		return false
	if game == null or not is_instance_valid(game):
		return false
	for crate in game.get_tree().get_nodes_in_group("crates"):
		if crate.get("is_reached") != null:
			crate.is_reached = true
	if game.has_method("_on_crate_reached_dest"):
		game.call("_on_crate_reached_dest")
	return true
