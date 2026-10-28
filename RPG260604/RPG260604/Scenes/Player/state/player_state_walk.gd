extends PlayerState
class_name PlayerStateWalk

func enter_state() -> void:
	player.play_direction_anim(_get_move_anim_name())

@warning_ignore("unused_parameter")
func process_state(delta: float) -> void:
	# 关键修复：输入被对话框拦截时不执行任何移动逻辑
	if is_input_blocked():
		# 切换到idle状态以停止动画
		fsm.transition_to("Idle")
		return
	
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if Input.is_action_pressed("attack"):
		fsm.transition_to("Attack")
		return
	
	if input_vector == Vector2.ZERO:
		fsm.transition_to("Idle")
		return
	
	player.update_direction(input_vector)
	player.play_direction_anim(_get_move_anim_name())
	
	var speed: float = player.move_speed
	# Latch 逻辑: 启动需要 can_run (>20), 一旦启动则持续到体力耗尽或 Shift 释放
	var running := Input.is_key_pressed(KEY_SHIFT) and player.stamina_component.curr_stamina > 0
	if running and (player._is_running_active or player.can_run()):
		player._is_running_active = true
		speed = player.get_effective_run_multiplier() * speed
	else:
		player._is_running_active = false
	
	player.velocity = input_vector * speed
	player.move_and_slide()

func _get_move_anim_name() -> String:
	return "run" if player._is_running_active else "move"
