extends CharacterBody2D
@onready var animation_player: AnimatedSprite2D = $animation_player
@onready var sprite =$Sprite2D
var is_jumping = false
const SPEED = 600
const JUMP_VELOCITY = -800.0
const gravity = 1500

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if is_jumping:
		animation_player.play("jump")
	elif  direction == 0:
		animation_player.play("idle")
	else:
		animation_player.play("walk")
		sprite.flip_h = direction < 0
	

	move_and_slide()
