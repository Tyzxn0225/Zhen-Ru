extends PlayerState
class_name PlayerStateIdle

func enter_state() -> void:
	player._is_running_active = false
	player.play_direction_anim("idle")

func process_state(_delta: float) -> void:
	if is_input_blocked():
		return
	if player.is_moving():
		fsm.transition_to("Walk")

func _input(event: InputEvent) -> void:
	# 关键修复：只有自己是当前状态才响应输入
	if is_input_blocked():
		return
	
	
	if fsm.curr_state != self:
		return
		
	if event.is_action_pressed("attack"):
		fsm.transition_to("Attack")
		return
	
	if player.is_moving():
		fsm.transition_to("Walk")
