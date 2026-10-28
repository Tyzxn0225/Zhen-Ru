extends State
class_name PlayerState

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
#owner 属性的官方类型是 Node，不是 Player。需要此处转换

func is_input_blocked() -> bool:
	# 检查玩家是否被对话框拦截输入
	return player.is_input_blocked
#检查输入是否被对话框拦截，所有子状态都可以使用这个方法
