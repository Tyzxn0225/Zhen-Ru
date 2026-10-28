extends Button
class_name ShopButton

signal on_item_purchased

@onready var item_icon: TextureRect = $ItemIcon
@onready var price: Label = %Price

var item : ItemData

func load_item(data: ItemData) -> void:
	if data == null:
		return
	item = data
	if item_icon:
		item_icon.texture = data.icon
	if price:
		price.text = str(data.price)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	if GameData.coins < item.price:
		return
		
	GameData.coins -= item.price
	EventBus.coin_picked.emit()
	Inventory.add_item(item,1)
	on_item_purchased.emit()
