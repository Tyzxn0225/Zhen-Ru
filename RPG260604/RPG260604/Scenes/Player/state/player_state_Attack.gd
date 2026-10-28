extends PlayerState
class_name PlayerStateAttack

var weapon_rotation :Dictionary ={
	"down":180.0,
	"left":-90.0,
	"right":90.0,
	"up":0.0
}

func enter_state()-> void:
	player._is_running_active = false
		# 关键修复：输入被对话框拦截时不进入攻击状态
	if is_input_blocked():
		fsm.transition_to("Idle")
		return
		
	player.play_direction_anim("attack")
	weapon_position()
	if not player.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		player.anim_sprite.animation_finished.connect(_on_animation_finished)
#进入状态时播放动画，运行武器，并连接信号
func exit_state()-> void:
	if player.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		player.anim_sprite.animation_finished.disconnect(_on_animation_finished)
#退出状态时断开信号

func weapon_position()->void:
	var direction_key:String = player.last_direction
	#获取当前玩家面朝
	var marker:Marker2D = player.attack_positions[direction_key]
	#根据获取对应位置
	player.weapon.global_position = marker.global_position
	#将武器节点移动到标记点的全局位置
	player.weapon.rotation_degrees = weapon_rotation[direction_key]
	#设置武器旋转角度
	player.weapon.show()
	player.enable_weapon_collision(true)
	#显示武器节点,启用武器的碰撞检测
func _on_animation_finished()-> void:
	#当攻击动画播放完毕时自动调用
	player.enable_weapon_collision(false)
	#禁用武器碰撞
	player.weapon.hide()
	#隐藏武器
	if player.is_moving():
		fsm.transition_to("Walk")
	else:
		fsm.transition_to("Idle")
	# 根据当前是否有移动输入决定返回状态
