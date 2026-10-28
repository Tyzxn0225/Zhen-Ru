extends PanelContainer
class_name InventoryPanel

const SLOT_SCENE := preload("res://Scenes/UI/inventory_panel/inventory_slot.tscn")

@export var grabbed_slot: InventorySlot

## 同时可见的格子数，请在 ScrollContainer 检查器里调整高度与之对应
@export_range(1, 99) var visible_slot_count: int = 20
## 背包总格数（数据与 UI 格子数）
@export_range(1, 99) var total_slot_count: int = 40:
	set(value):
		total_slot_count = maxi(1, value)
		if is_node_ready() and Inventory:
			Inventory.set_capacity(total_slot_count)
			_build_slots()

@onready var container: GridContainer = %Container
@onready var label: Label = %Label

var slots: Array[InventorySlot] = []
var selected_slot_index: int = -1


func _ready() -> void:
	if not Inventory.on_inventory_changed.is_connected(_on_inventory_changed):
		Inventory.on_inventory_changed.connect(_on_inventory_changed)
	if not EventBus.coin_picked.is_connected(_update_coin_label):
		EventBus.coin_picked.connect(_update_coin_label)
	Inventory.set_capacity(total_slot_count)
	_build_slots()
	_update_coin_label()


func _build_slots() -> void:
	for child in container.get_children():
		child.queue_free()
	slots.clear()

	for i in total_slot_count:
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		slot.slot_index = i
		if not slot.on_slot_clicked.is_connected(_on_slot_clicked):
			slot.on_slot_clicked.connect(_on_slot_clicked)
		if not slot.on_slot_hovered.is_connected(_on_slot_hovered):
			slot.on_slot_hovered.connect(_on_slot_hovered)
		container.add_child(slot)
		slots.append(slot)

	_on_inventory_changed()


func _process(_delta: float) -> void:
	if grabbed_slot and grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position()


func select_slots(slot_index: int) -> void:
	if grabbed_slot == null:
		return
	deselect_slot()
	selected_slot_index = slot_index
	var slot: SlotData = Inventory.get_slot(slot_index)
	grabbed_slot.load_data(slot)
	grabbed_slot.show()


func deselect_slot() -> void:
	selected_slot_index = -1
	if grabbed_slot:
		grabbed_slot.hide()


func handle_left_button(slot_index: int) -> void:
	if selected_slot_index >= 0 and selected_slot_index != slot_index:
		var from_item = Inventory.get_slot_item(selected_slot_index)
		var to_item = Inventory.get_slot_item(slot_index)
		if from_item and to_item and from_item == to_item:
			Inventory.merge_slots(selected_slot_index, slot_index)
		else:
			Inventory.swap_slots(selected_slot_index, slot_index)
		deselect_slot()
	elif selected_slot_index == slot_index:
		deselect_slot()
	elif Inventory.get_slot(slot_index):
		select_slots(slot_index)


func handle_right_button(slot_index: int) -> void:
	var item = Inventory.get_slot_item(slot_index)
	if not item:
		return
	if item is EquipData:
		Inventory.equip_item(slot_index)
	else:
		Inventory.use_item(slot_index)
		EventBus.on_inventory_used_item.emit(item)


func _on_inventory_changed() -> void:
	for i in slots.size():
		if slots[i] == null:
			continue
		slots[i].load_data(Inventory.get_slot(i))


func _update_coin_label() -> void:
	label.text = str(GameData.coins)


func _on_slot_clicked(slot_index: int, button: int) -> void:
	match button:
		MOUSE_BUTTON_LEFT:
			handle_left_button(slot_index)
		MOUSE_BUTTON_RIGHT:
			handle_right_button(slot_index)


func _on_slot_hovered(_slot_index: int) -> void:
	pass
