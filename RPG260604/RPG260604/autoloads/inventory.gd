# ==============================================================================
# 背包系统 (Inventory)
# 功能概述：管理玩家背包中的物品，支持添加、移除、使用、装备等操作
# 设计模式：单例模式（通过自动加载实现全局访问）
# 核心机制：使用数组存储槽位数据，支持物品堆叠和装备管理
# 作者：系统自动生成
# 版本：1.0
# ==============================================================================
extends Node

# ==============================================================================
# 信号定义
# ==============================================================================

# 【信号】背包内容发生变化时触发
# 使用场景：通知UI刷新背包显示
signal on_inventory_changed

# 【信号】装备状态发生变化时触发
# 使用场景：通知UI刷新装备栏显示
signal on_equipment_changed

# ==============================================================================
# 常量定义
# ==============================================================================

# 【常量】默认背包容量（运行后由 InventoryPanel 检查器中的 total_slot_count 同步）
const DEFAULT_CAPACITY: int = 40

# ==============================================================================
# 成员变量定义
# ==============================================================================

# 【核心数据结构】背包数组
# 存储格式：Array<SlotData>
#   - 每个元素为SlotData类型或null（空槽位）
#   - SlotData包含物品数据(ItemData)和数量(quantity)
#   - 数组索引即为槽位编号（0-29）
var inventory: Array[SlotData]

# ==============================================================================
# 生命周期函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：_ready
# 触发时机：节点添加到场景树时自动调用
# 功能：初始化背包数组，创建空槽位
# ------------------------------------------------------------------------------
func _ready() -> void:
	inventory.clear()
	inventory.resize(DEFAULT_CAPACITY)


func set_capacity(size: int) -> void:
	size = maxi(1, size)
	if inventory.size() == size:
		return
	inventory.resize(size)
	on_inventory_changed.emit()


func get_capacity() -> int:
	return inventory.size()

# ==============================================================================
# 槽位查询函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：get_empty_slot_indexes
# 功能：获取所有空槽位的索引列表
# 返回值：Array<int> - 空槽位索引数组（如[0, 5, 12]表示第0、5、12号槽位为空）
# 使用场景：
#   - 添加物品时查找可用槽位
#   - 检查背包是否已满
# ------------------------------------------------------------------------------
func get_empty_slot_indexes() -> Array[int]:
	var empty: Array[int] = []
	
	# 遍历所有槽位（0到29）
	for i in inventory.size():
		# 如果槽位为空（null），将索引加入列表
		if inventory[i] == null:
			empty.append(i)
	
	return empty

# ------------------------------------------------------------------------------
# 函数：find_item_indexes
# 功能：查找指定物品在背包中的所有槽位索引
# 参数：
#   item: ItemData - 要查找的物品数据
#   with_space: bool - 是否只查找有堆叠空间的槽位（默认false）
# 返回值：Array<int> - 符合条件的槽位索引数组
# 使用场景：
#   - with_space=true：添加物品时查找可堆叠的槽位
#   - with_space=false：查找所有包含该物品的槽位
# ------------------------------------------------------------------------------
func find_item_indexes(item: ItemData, with_space: bool = false) -> Array[int]:
	var found: Array[int] = []
	
	# 遍历所有槽位
	for i in inventory.size():
		var slot = inventory[i]
		
		# 检查槽位非空且物品匹配
		if slot and slot.item == item:
			# 根据with_space参数决定是否检查堆叠空间
			if with_space:
				# 只返回未达到最大堆叠数量的槽位
				if slot.quantity < item.max_stack:
					found.append(i)
			else:
				# 返回所有包含该物品的槽位
				found.append(i)
	
	return found

# ------------------------------------------------------------------------------
# 函数：get_slot
# 功能：获取指定槽位的数据
# 参数：
#   index: int - 槽位索引（0-29）
# 返回值：SlotData - 槽位数据（索引无效时返回null）
# 使用场景：
#   - 查询特定槽位的物品信息
#   - 验证槽位是否有效
# ------------------------------------------------------------------------------
func get_slot(index: int) -> SlotData:
	# 边界检查：确保索引在有效范围内
	if index >= 0 and index < inventory.size():
		return inventory[index]
	return null

# ------------------------------------------------------------------------------
# 函数：get_slot_item
# 功能：获取指定槽位中的物品数据
# 参数：
#   index: int - 槽位索引（0-29）
# 返回值：ItemData - 物品数据（槽位为空时返回null）
# 使用场景：
#   - 快速获取槽位中的物品信息
# ------------------------------------------------------------------------------
func get_slot_item(index: int) -> ItemData:
	var slot = get_slot(index)
	if slot:
		return slot.item
	return null

# ------------------------------------------------------------------------------
# 函数：has_empty_slot
# 功能：检查背包是否有可用空槽位
# 返回值：bool - true表示有空格位，false表示背包已满
# 使用场景：
#   - 装备卸下前检查背包是否有空间
#   - 添加物品前验证容量
# ------------------------------------------------------------------------------
func has_empty_slot() -> bool:
	return get_empty_slot_indexes().size() > 0

# ------------------------------------------------------------------------------
# 函数：set_slot
# 功能：设置指定槽位的数据
# 参数：
#   index: int - 槽位索引（0-29）
#   slot_data: SlotData - 槽位数据（null表示清空槽位）
# 返回值：void
# 使用场景：
#   - 直接设置槽位内容（如拖拽放置）
#   - 清空指定槽位
# ------------------------------------------------------------------------------
func set_slot(index: int, slot_data: SlotData) -> void:
	if index >= 0 and index < inventory.size():
		inventory[index] = slot_data
		on_inventory_changed.emit()

# ==============================================================================
# 物品添加/移除函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：add_item
# 功能：向背包中添加物品
# 参数：
#   item: ItemData - 要添加的物品数据
#   amount: int - 添加数量（默认1）
# 返回值：void
# 执行流程：
#   1. 安全检查 → 2. 尝试堆叠到已有槽位 → 3. 使用空槽位 → 4. 通知UI更新
# 设计要点：
#   - 优先堆叠到已有槽位（如果物品可堆叠）
#   - 剩余数量使用新槽位
#   - 支持批量添加
# ------------------------------------------------------------------------------
func add_item(item: ItemData, amount: int = 1) -> void:
	# 【安全检查】物品数据为空时直接返回
	if not item:
		return
	
	# 记录剩余待添加数量
	var remaining = amount
	
	# 阶段1：尝试堆叠到已有槽位（仅适用于可堆叠物品）
	if item.max_stack > 1:
		# 获取所有有堆叠空间的槽位
		for index in find_item_indexes(item, true):
			# 如果已添加完，提前退出
			if remaining <= 0:
				break
			
			var slot = inventory[index]
			# 计算该槽位还能容纳的数量
			var space = item.max_stack - slot.quantity
			# 取最小值（可用空间和剩余数量）
			var to_give = min(space, remaining)
			
			# 更新槽位数量和剩余数量
			slot.quantity += to_give
			remaining -= to_give
	
	# 阶段2：使用空槽位放置剩余物品
	if remaining > 0:
		# 获取所有空槽位
		for index in get_empty_slot_indexes():
			# 如果已添加完，提前退出
			if remaining <= 0:
				break
			
			# 计算本次放入数量（不超过单个槽位最大堆叠数）
			var to_give = min(item.max_stack, remaining)
			# 创建新的SlotData对象并放入槽位
			inventory[index] = SlotData.new(item, to_give)
			remaining -= to_give
	
	# 如果有实际添加的物品，发送背包变化信号
	var added = amount - remaining
	if added > 0:
		on_inventory_changed.emit()

# ==============================================================================
# 装备管理函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：equip_item
# 功能：装备背包中的物品
# 参数：
#   slot_index: int - 物品所在的槽位索引
# 返回值：void
# 执行流程：
#   1. 获取槽位数据 → 2. 验证物品类型 → 3. 保存当前装备 → 4. 装备新物品 → 5. 旧装备放回背包
# 设计要点：
#   - 仅支持EquipData类型物品
#   - 自动替换当前装备并将其放回背包
# ------------------------------------------------------------------------------
func equip_item(slot_index: int) -> void:
	# 获取槽位数据
	var slot: SlotData = get_slot(slot_index)
	
	# 【安全检查】槽位为空时返回
	if not slot:
		return
	
	# 【类型检查】物品必须是装备类型
	if not slot.item is EquipData:
		return
	
	# 转换为装备数据
	var equip: EquipData = slot.item as EquipData
	# 获取装备槽位键（如"weapon", "armor"）
	var equip_key: String = equip.get_equip_key()
	
	# 获取当前装备的物品（用于后续放回背包）
	var current_equipped_item = GameData.equipement[equip_key]
	
	# 装备新物品
	GameData.equipement[equip_key] = equip
	
	# 清空原槽位
	inventory[slot_index] = null
	
	# 如果之前有装备，将其放回背包
	if current_equipped_item:
		add_item(current_equipped_item, 1)
	
	# 发送信号通知UI更新
	on_inventory_changed.emit()
	on_equipment_changed.emit()

# ------------------------------------------------------------------------------
# 函数：unequip_item
# 功能：卸下指定部位的装备
# 参数：
#   equip_type: EquipData.EquipType - 装备部位类型（如武器、头盔、胸甲等）
# 返回值：void
# 执行流程：
#   1. 获取装备槽位键 → 2. 获取当前装备 → 3. 添加到背包 → 4. 清空装备槽位
# ------------------------------------------------------------------------------
func unequip_item(equip_type: EquipData.EquipType) -> void:
	# 使用静态方法将装备类型转换为正确的键名
	var equip_key = EquipData.equip_type_to_string(equip_type)
	
	# 验证键名是否有效
	if equip_key.empty():
		print("【错误】无效的装备类型: ", equip_type)
		return
	
	# 获取当前装备的物品
	var equipped_item = GameData.equipement.get(equip_key)
	
	# 如果没有装备，直接返回
	if not equipped_item:
		return
	
	# 将卸下的装备添加到背包
	add_item(equipped_item, 1)
	
	# 清空装备槽位
	GameData.equipement[equip_key] = null
	
	# 发送装备变化信号
	on_equipment_changed.emit()

# ==============================================================================
# 物品使用函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：use_item
# 功能：使用背包中指定槽位的可消耗物品
# 参数：
#   slot_index: int - 物品所在的槽位索引
# 返回值：void
# 执行流程：
#   1. 获取槽位数据 → 2. 验证物品可消耗 → 3. 减少物品数量 → 4. 应用物品效果 → 5. 通知UI更新
# 关键依赖：
#   - ItemEffectHandler: 处理物品效果（如食物恢复血量）
#   - Refs.player: 全局玩家引用
# ------------------------------------------------------------------------------
func use_item(slot_index) -> void:
	# 获取槽位数据
	var slot: SlotData = inventory[slot_index]
	
	# 【安全检查】槽位为空时返回
	if not slot:
		return
	
	# 【类型检查】物品必须是可消耗的
	if not slot.item.is_consumable:
		return
	
	# 保存物品引用（用于后续效果处理）
	var item = slot.item
	
	# 减少物品数量
	slot.quantity -= 1
	
	# 如果数量减到0，清空槽位
	if slot.quantity <= 0:
		inventory[slot_index] = null
	
	# 【核心调用】通过自动加载节点获取ItemEffectHandler并应用物品效果
	# get_tree().get_root().get_node("NodeName") 是获取自动加载单例的标准方式
	get_tree().get_root().get_node("ItemEffectHandler").apply_item_effect(item, Refs.player)
	
	# 发送背包变化信号
	on_inventory_changed.emit()

# ------------------------------------------------------------------------------
# 函数：can_use_item
# 功能：检查指定槽位的物品是否可以使用
# 参数：
#   slot_index: int - 槽位索引
# 返回值：bool - 可使用返回true，否则返回false
# 使用场景：
#   - UI层判断是否显示使用按钮
#   - 防止无效的物品使用操作
# ------------------------------------------------------------------------------
func can_use_item(slot_index: int) -> bool:
	var slot: SlotData = get_slot(slot_index)
	# 槽位非空且物品可消耗
	return slot and slot.item.is_consumable

# ==============================================================================
# 槽位操作函数（拖拽/合并）
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：swap_slots
# 功能：交换两个槽位的物品
# 参数：
#   from_index: int - 源槽位索引
#   to_index: int - 目标槽位索引
# 返回值：void
# 使用场景：
#   - 玩家拖拽物品到另一个槽位
#   - 整理背包时的位置调整
# ------------------------------------------------------------------------------
func swap_slots(from_index: int, to_index: int) -> void:
	# 边界检查：确保索引有效
	if from_index < 0 or from_index >= inventory.size():
		return
	if to_index < 0 or to_index >= inventory.size():
		return
	
	# 使用临时变量交换两个槽位内容
	var temp = inventory[from_index]
	inventory[from_index] = inventory[to_index]
	inventory[to_index] = temp
	
	# 发送背包变化信号
	on_inventory_changed.emit()

# ------------------------------------------------------------------------------
# 函数：merge_slots
# 功能：尝试将一个槽位的物品合并到另一个槽位
# 参数：
#   from_index: int - 源槽位索引（要移动的物品）
#   to_index: int - 目标槽位索引（目标位置）
# 返回值：void
# 执行流程：
#   1. 验证槽位有效性 → 2. 验证物品类型相同 → 3. 验证可堆叠 → 4. 执行合并 → 5. 清理空槽位
# 使用场景：
#   - 玩家将物品拖拽到同类物品槽位上
#   - 自动整理背包时合并堆叠
# ------------------------------------------------------------------------------
func merge_slots(from_index: int, to_index: int) -> void:
	# 获取源槽位和目标槽位数据
	var from_slot: SlotData = get_slot(from_index)
	var to_slot: SlotData = get_slot(to_index)
	
	# 【安全检查】任一槽位为空时返回
	if not from_slot or not to_slot:
		return
	
	# 【类型检查】物品类型必须相同才能合并
	if from_slot.item != to_slot.item:
		return
	
	# 获取物品数据
	var item = from_slot.item
	
	# 【堆叠检查】物品必须可堆叠（max_stack > 1）
	if item.max_stack <= 1:
		return
	
	# 计算目标槽位的可用空间
	var space = item.max_stack - to_slot.quantity
	# 计算要移动的数量（不超过可用空间和源槽位数量）
	var to_move = min(space, from_slot.quantity)
	
	# 执行合并
	to_slot.quantity += to_move
	from_slot.quantity -= to_move
	
	# 清理源槽位（如果已空）
	if from_slot.quantity <= 0:
		inventory[from_index] = null
	# 如果目标槽位已满但源槽位还有物品，交换位置（拖拽操作的特殊处理）
	elif space <= 0:
		swap_slots(from_index, to_index)
	
	# 发送背包变化信号
	on_inventory_changed.emit()
