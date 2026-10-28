extends Node

var player: Player
var hud: HUD
var navigation: TileMapLayer
var current_npc: NPC            # 当前正在与玩家交互的 NPC ( 对话 / 剧情移动 时自动设置 )


const SHOP_BUTTON_SCENE = preload("uid://ckb58fjpovdm1")


## 通过节点名称获取场景中的 NPC (供 dialogue do 调用)
func get_npc_by_name(npc_name: String) -> NPC:
	var scene := get_tree().current_scene
	if not scene:
		return null
	for child in scene.find_children("*", "NPC", true, false):
		if child.name == npc_name:
			return child
	return null
