extends Node
class_name StaminaComponent

signal on_stamina_changed(curr_stamina: float, max_stamina: float)
signal on_max_stamina_changed(new_max: float)
signal on_stamina_depleted

var max_stamina: float
var curr_stamina: float

func setup(value: float) -> void:
	max_stamina = value
	curr_stamina = value
	on_stamina_changed.emit(curr_stamina, max_stamina)

## 修改体力上限 (物品/升级调用), 自动 clamp 当前体力并发射信号
func set_max(value: float) -> void:
	if value <= 0:
		return
	max_stamina = value
	curr_stamina = min(curr_stamina, max_stamina)
	on_max_stamina_changed.emit(max_stamina)
	on_stamina_changed.emit(curr_stamina, max_stamina)

## 消耗体力, 向下 clamp 到 0, 归零时发射信号
func consume(value: float) -> void:
	if curr_stamina <= 0:
		return
	var was_above_zero := curr_stamina > 0
	curr_stamina = max(curr_stamina - value, 0)
	on_stamina_changed.emit(curr_stamina, max_stamina)
	if was_above_zero and curr_stamina <= 0:
		on_stamina_depleted.emit()

## 恢复体力, 向上 clamp 到 max_stamina
func recover(value: float) -> void:
	if curr_stamina >= max_stamina:
		return
	curr_stamina = min(curr_stamina + value, max_stamina)
	on_stamina_changed.emit(curr_stamina, max_stamina)
