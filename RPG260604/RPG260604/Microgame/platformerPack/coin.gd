extends Area2D

@export var coin_value: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.collision_layer & 2 == 0:
		return
	GameData.coins += coin_value
	GameData.coins_picked_this_session += coin_value
	EventBus.coin_picked.emit()
	queue_free()
