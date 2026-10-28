class_name TestKey
extends RefCounted
## 输入映射「测试键」的只读检测。未配置该动作时始终返回 false，不影响其它逻辑。

const ACTION := &"测试键"


static func is_just_pressed(event: InputEvent) -> bool:
	if event == null or not InputMap.has_action(ACTION):
		return false
	return event.is_action_pressed(ACTION)
