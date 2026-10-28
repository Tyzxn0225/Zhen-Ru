extends Node
class_name HealthComponent

signal on_health_changed(curr_health : float)
signal on_dead

var max_health:float
var curr_health:float

func setup(value:float)-> void:
	max_health = value
	curr_health = value
	
func take_damage(value:float)-> void:
	if curr_health <= 0:
		return
	curr_health = max(curr_health - value,0)
	#返回”当前生命值“和”0“中两者的最大值，即当前生命值不小于0
	#curr_health -= value
	#if curr_health <= 0:
	#	curr_health = 0
	on_health_changed.emit(curr_health)
	if curr_health <= 0:
		on_dead.emit()
		

func heal(value:float)->void:
	curr_health += value
	curr_health = min(curr_health,max_health)
	on_health_changed.emit(curr_health)
