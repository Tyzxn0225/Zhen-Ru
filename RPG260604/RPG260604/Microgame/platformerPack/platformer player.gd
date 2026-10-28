extends CharacterBody2D

const gravity = 1500
const speed =500
const jump_force = 600

var is_jumping = false

@onready var animation_player: AnimatedSprite2D = $animation_player
@onready var sprite =$Sprite2D

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	
	var direction = Input.get_action_strength("move_right")-Input.get_action_strength("move_left")
	velocity.x = direction * speed
	
	move_and_slide()
	
	if is_on_floor():
		is_jumping = false
	
	
	if is_jumping:
		animation_player.play("jump")
	elif  direction == 0:
		animation_player.play("idle")
	else:
		animation_player.play("walk")
		sprite.flip_h = direction < 0
	
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") and not is_jumping:
		velocity.y = -jump_force
		is_jumping =true
		
	
	
