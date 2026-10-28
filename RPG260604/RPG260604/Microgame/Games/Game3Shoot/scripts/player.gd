extends CharacterBody2D

# 玩家移动速度和动画播放器
@export var move_speed : float = 50
@export var animator : AnimatedSprite2D

# bool 变量：true或者false
@export var is_game_over : bool = false

@export var bullet_scene : PackedScene

func _process(delta: float) -> void:
	if velocity == Vector2.ZERO or is_game_over:
		$RunningSound.stop()
	elif not $RunningSound.playing:
		$RunningSound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# 如果游戏没有结束，则基于玩家输入移动角色
	if not is_game_over:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * move_speed
		
		# 如果速度为0，播放待机动画
		if velocity == Vector2.ZERO:
			animator.play("idle")
		# 如果速度不为0，播放跑步动画
		else:
			animator.play("run")
		
		move_and_slide()
		
		# 检测空格键开火（使用自定义动作）
		if Input.is_action_just_pressed("fire"):
			_on_fire()
		

func game_over():
	if not is_game_over:
		# 设置游戏结束，播放失败动画
		is_game_over = true
		animator.play("lose")
		
		get_tree().current_scene.show_game_over()
		# $GameOverSound.play()
		
		# 等待三秒后重启游戏
		# await get_tree().create_timer(3).timeout
		# get_tree().reload_current_scene()
		
func on_win():
	if not is_game_over:
		# 游戏胜利，播放胜利动画
		is_game_over = true
		animator.play("win")
		print("玩家胜利动画播放")

func _on_fire() -> void:
	# 如果玩家站立不动或游戏结束了，则不能发射子弹
	# if velocity == Vector2.ZERO or is_game_over:
		# return
	# 如果游戏结束了，则不能发射子弹
	if is_game_over:
		return
	# 生成子弹节点，设置正确的子弹位置，并将其添加进场景树
	var bullet_node = bullet_scene.instantiate()
	bullet_node.position = position + Vector2(40, 0)
	get_tree().current_scene.add_child(bullet_node)
	$FireSound.play()
	

	
	
