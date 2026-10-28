extends Resource
class_name SlotData

#指示任何物品的一组数据

@export var item :ItemData
#槽位中存放的物品的各种数据（引用一个 ItemData 资源）
@export var quantity :int =1 
#该物品在槽位中的数量，默认1
func _init(_item:ItemData,_quantity:int) -> void:
	item = _item
	quantity = _quantity
	#允许在创建 SlotData 实例时直接传入物品和数量进行初始化。
