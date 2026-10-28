extends Area2D

@export var slime_speed : float = -100



var is_dead : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# 检查游戏是否结束
	var game_manager = get_tree().current_scene
	if game_manager.game_ended:
		return
		
	# 只有在目标没有被消灭的情况下，它才会移动
	if not is_dead:
		position += Vector2(slime_speed, 0) * delta


func _on_area_entered(area: Area2D) -> void:
# 如果目标碰到 resist 区域（游戏边界），游戏失败
	if area.name == "resist" and not is_dead:
		get_tree().current_scene.get_node("Player").game_over()
		return

	# 检测撞到目标的是否是子弹
	if area.is_in_group("bullet"):
		# 播放被消灭的动画、消除子弹
		$AnimatedSprite2D.play("death")
		is_dead = true
		area.queue_free()
		# 根节点挂载了 GameManager 脚本，通过 MicroGameManage 访问分数
		MicroGameManage.get_instance().add_score(1)
		print("击中敌人，当前分数: ", MicroGameManage.get_instance().current_score)
		$DeathSound.play()
		
		# 延迟0.6秒后移除目标节点
		await get_tree().create_timer(0.6).timeout
		queue_free()
