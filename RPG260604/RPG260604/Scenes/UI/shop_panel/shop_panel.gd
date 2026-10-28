extends Control
class_name ShopPanel

const SHOP_BUTTON_SCENE := preload("res://Scenes/UI/shop_panel/shop_button.tscn")

@export var items: Array[ItemData]
@onready var container: GridContainer = %Container
@onready var total_coins: Label = %TotalCoins


func _ready() -> void:
	for child in container.get_children():
		child.queue_free()
	call_deferred("_populate_shop_items")
	total_coins.text = str(GameData.coins)


func _populate_shop_items() -> void:
	if not container:
		push_error("ShopPanel: Container 未找到")
		return
	for item: ItemData in items:
		if item == null:
			continue
		var shop_button := SHOP_BUTTON_SCENE.instantiate() as ShopButton
		if shop_button == null:
			push_error("ShopPanel: 无法实例化 ShopButton")
			continue
		container.add_child(shop_button)
		shop_button.load_item(item)
		if not shop_button.on_item_purchased.is_connected(_on_item_purchased):
			shop_button.on_item_purchased.connect(_on_item_purchased)


func _on_item_purchased() -> void:
	total_coins.text = str(GameData.coins)


func _on_close_button_pressed() -> void:
	hide()
