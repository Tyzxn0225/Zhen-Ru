extends Button
class_name  InventorySlot

signal  on_slot_clicked(slot_index:int,button:int)
#按下时信号
signal  on_slot_hovered(slot_index:int)
#悬停时信号

@onready var item_icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel
@onready var selector: TextureRect = $Selector

var slot_index:int = -1
#记录这个UI槽位在背包数组中的索引位置。（第几格）
#初始值 -1 表示尚未分配索引，或者该槽位无效/未初始化。
var slot_date :SlotData
#保存当前槽位对应的数据模型（包含物品引用和数量）。
#未显式赋值，默认为 null，表示空槽位。

func load_data(data:SlotData)-> void:
	#当背包系统需要刷新这个格子的显示ui时
	#会调用这个方法并传入一个SlotData对象。
	slot_date = data
	#将传入的数据保存到变量中。
	if slot_date and slot_date.item:
		#slot_data 不为空（不是null）
		#slot_data.item 不为空（即格子里有物品）
		item_icon.texture = slot_date.item.icon
		#将物品的图标显示在界面上。
		item_icon.show()
		
		if slot_date.quantity> 1 :
			#物品数大于1时显示数量
			amount_label.text = str(slot_date.quantity)
			amount_label.show()
		else:
			amount_label.hide()
			#物品数其余情况不显示数量	
	else:
		clear_slot()	 
		#没有有效槽位时清除数据
func clear_slot()->void:
	slot_date =null
	item_icon.texture = null
	item_icon.hide()
	amount_label.hide()


func _on_mouse_entered() -> void:
	selector.show()
	on_slot_hovered.emit(slot_index)
	if slot_date and slot_date.item:
		UIManager.show_custom_hint(slot_date.item.name, slot_date.item.description)

func _on_mouse_exited() -> void:
	selector.hide()
	UIManager.hide_custom_hint()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		on_slot_clicked.emit(slot_index,event.button_index)
