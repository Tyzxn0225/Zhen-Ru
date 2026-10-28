extends PanelContainer
class_name EquipmentPanel

@onready var slots: Array[EquipmentSlot] = [
	%HelmetSlot, 
	%WeaponSlot,
	%BodySlot, 
	%LegsSlot, 
	%RingSlot
]

@onready var hint_label: Label = get_parent().get_node_or_null("%HintLabel")

func _ready() -> void:
	# 设置每个槽位的装备类型
	slots[0].equip_type = EquipData.EquipType.HELMET   # HelmetSlot
	slots[1].equip_type = EquipData.EquipType.WEAPON  # WeaponSlot
	slots[2].equip_type = EquipData.EquipType.BODY    # BodySlot
	slots[3].equip_type = EquipData.EquipType.LEGS    # LegsSlot
	slots[4].equip_type = EquipData.EquipType.RING    # RingSlot
	
	# 添加重复连接检查
	if not Inventory.on_equipment_changed.is_connected(_on_equipment_changed):
		Inventory.on_equipment_changed.connect(_on_equipment_changed)
	for slot: EquipmentSlot in slots:
		if not slot.on_slot_clicked.is_connected(_on_slot_clicked):
			slot.on_slot_clicked.connect(_on_slot_clicked)

func _on_equipment_changed() -> void:
	for slot in slots:
		var equip_key = EquipData.equip_type_to_string(slot.equip_type)
		var equip_data = GameData.equipement.get(equip_key)
		slot.load_data(equip_data)

func _on_slot_clicked(equip_type: EquipData.EquipType, button: int, slot: EquipmentSlot) -> void:
	match button:
		MOUSE_BUTTON_LEFT:
			_on_slot_left_clicked(equip_type, slot)
		MOUSE_BUTTON_RIGHT:
			_on_slot_right_clicked(equip_type, slot)

func _on_slot_left_clicked(equip_type: EquipData.EquipType, slot: EquipmentSlot) -> void:
	if slot and slot.equipped_data:
		print("【装备面板】查看装备详情: ", slot.equipped_data.name)

func _on_slot_right_clicked(equip_type: EquipData.EquipType, slot: EquipmentSlot) -> void:
	if not slot or not slot.equipped_data:
		_show_hint("该装备槽为空")
		return
	
	var equip_data = slot.equipped_data
	
	if not _can_unequip(equip_data):
		_show_hint("该装备无法卸下")
		_log_operation(equip_data, "FAILED", "装备不可卸下")
		return
	
	if not Inventory.has_empty_slot():
		_show_hint("背包空间不足，无法卸下装备")
		_log_operation(equip_data, "FAILED", "背包空间不足")
		return
	
	var success = _execute_unequip(equip_type, equip_data, slot)
	
	if success:
		_show_hint("装备已卸下")
		_log_operation(equip_data, "SUCCESS", "装备成功卸下")
	else:
		_show_hint("装备卸下失败，请重试")
		_log_operation(equip_data, "FAILED", "系统异常")

func _can_unequip(equip_data: EquipData) -> bool:
	if equip_data.has_method("is_quest_bounded") and equip_data.is_quest_bounded:
		return false
	if equip_data.has_method("cannot_unequip") and equip_data.cannot_unequip:
		return false
	return true

func _execute_unequip(equip_type: EquipData.EquipType, equip_data: EquipData, slot: EquipmentSlot) -> bool:
	var success = false
	
	GameData.equipement[EquipData.equip_type_to_string(equip_type)] = null
	
	Inventory.add_item(equip_data, 1)
	
	slot.clear_slot()
	
	Inventory.on_inventory_changed.emit()
	Inventory.on_equipment_changed.emit()
	
	return true

func _show_hint(message: String) -> void:
	if hint_label:
		hint_label.text = message
		hint_label.show()
		var tween = create_tween()
		tween.tween_interval(3)
		tween.tween_callback(hint_label.hide)
	else:
		print("【提示】", message)

func _log_operation(equip_data: EquipData, status: String, reason: String) -> void:
	var timestamp = Time.get_datetime_string_from_system()
	var log_entry = {
		"timestamp": timestamp,
		"item_id": equip_data.id,
		"item_name": equip_data.name,
		"operation": "UNEQUIP",
		"status": status,
		"reason": reason
	}
	print("【装备操作日志】", JSON.stringify(log_entry))
