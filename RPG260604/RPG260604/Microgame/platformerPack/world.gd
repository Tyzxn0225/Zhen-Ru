extends Node

@onready var coin_label: Label = %Label
var _base_coins: int

func _ready() -> void:
	
	if not EventBus.coin_picked.is_connected(_on_coin_picked):
		EventBus.coin_picked.connect(_on_coin_picked)
	GameData.coins_picked_this_session = 0
	_base_coins = GameData.coins
	_update_coin_display()

func _on_coin_picked() -> void:
	_update_coin_display()

func _update_coin_display() -> void:
	if not coin_label:
		return
	var picked := GameData.coins_picked_this_session
	if picked > 0:
		coin_label.text = "%d+%d" % [_base_coins, picked]
	else:
		coin_label.text = str(GameData.coins)
