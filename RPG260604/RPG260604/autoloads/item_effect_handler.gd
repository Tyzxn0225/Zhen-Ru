# ==============================================================================
# 物品效果处理器 (ItemEffectHandler)
# 功能概述：负责处理所有可消耗物品的实际游戏效果
# 设计模式：策略模式 + 观察者模式
# 核心机制：通过注册表将物品类型与处理函数动态绑定，实现效果的灵活分派
# 作者：系统自动生成
# 版本：1.0
# ==============================================================================
extends Node
class_name ItemEffectHandler

# ==============================================================================
# 信号定义
# ==============================================================================

# 【信号】当物品效果被成功应用时触发
# 参数说明：
#   item_id: String - 物品唯一标识符
#   effect_type: String - 效果类型字符串（如 "FOOD", "POTION"）
#   value: float - 效果数值（如恢复3点HP）
signal on_item_effect_applied(item_id: String, effect_type: String, value: float)

# ==============================================================================
# 成员变量定义
# ==============================================================================

# 【核心数据结构】效果注册表
# 作用：存储物品类型与对应处理函数的映射关系
# 数据格式：Dictionary<int, Callable>
#   - Key: ItemData.Category 枚举值（FOOD=0, ORE=1, POTION=2, SCROLL=3, EQUIPMENT=4）
#   - Value: 处理函数引用，签名为 func(item: ItemData, user: Node)
var effect_registry: Dictionary = {}

# ==============================================================================
# 生命周期函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：_ready
# 触发时机：节点添加到场景树时自动调用
# 功能：初始化效果注册表，注册所有默认的物品类型处理函数
# ------------------------------------------------------------------------------
func _ready():
	_register_default_effects()

# ==============================================================================
# 私有辅助函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：_register_default_effects
# 功能：注册所有默认物品类型的效果处理函数
# 设计意图：通过集中注册机制，实现效果处理的可配置性和扩展性
# 扩展方式：新增物品类型时，只需添加对应的处理函数并在此注册即可
# ------------------------------------------------------------------------------
func _register_default_effects():
	# 注册食物类型处理函数
	effect_registry[ItemData.Category.FOOD] = _handle_food_effect
	# 注册药水类型处理函数
	effect_registry[ItemData.Category.POTION] = _handle_potion_effect
	# 注册卷轴类型处理函数
	effect_registry[ItemData.Category.SCROLL] = _handle_scroll_effect
	# 注册资源类型处理函数（矿石等不可直接使用）
	effect_registry[ItemData.Category.ORE] = _handle_ore_effect
	# 注册装备类型处理函数（装备不可消耗使用）
	effect_registry[ItemData.Category.EQUIPMENT] = _handle_equipment_effect

# ==============================================================================
# 公共核心函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：apply_item_effect
# 功能：根据物品类型调用对应的效果处理函数
# 参数：
#   item: ItemData - 要应用效果的物品数据（必需）
#   user: Node - 使用物品的角色节点（可选，默认null时使用全局玩家）
# 返回值：void（无返回值）
# 执行流程：
#   1. 空值检查 → 2. 查找处理函数 → 3. 执行处理函数 → 4. 发射效果应用信号
# 错误处理：
#   - item为null时直接返回
#   - 未找到处理函数时输出警告日志
# ------------------------------------------------------------------------------
func apply_item_effect(item: ItemData, user: Node = null):
	# 【安全检查】物品数据为空时直接返回，防止空指针异常
	if not item:
		return
	
	# 【策略分派】根据物品品类从注册表中获取对应的处理函数
	var effect_func = effect_registry.get(item.category)
	
	# 如果找到对应的处理函数
	if effect_func:
		# 【动态调用】使用call方法调用处理函数，传入物品和使用者参数
		effect_func.call(item, user)
		# 【事件通知】发射信号，通知其他模块（如UI）效果已应用
		on_item_effect_applied.emit(item.id, str(item.category), item.value)
	else:
		# 【错误处理】未找到处理函数时输出警告日志
		print("Warning: No effect handler registered for item category: ", item.category)

# ==============================================================================
# 效果处理函数（按物品类型分类）
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：_handle_food_effect
# 功能：处理食物类物品的效果（恢复生命值）
# 参数：
#   item: ItemData - 食物物品数据
#   user: Node - 食用食物的角色
# 实现逻辑：
#   1. 检查食物是否有有效的恢复值(value > 0)
#   2. 优先使用传入的user对象，其次降级使用全局玩家Refs.player
#   3. 获取角色的HealthComponent组件并调用heal方法恢复血量
# 设计要点：
#   - 支持自定义使用者，便于AI角色使用食物
#   - 双重降级机制确保即使没有传入user也能正常工作
# ------------------------------------------------------------------------------
func _handle_food_effect(item: ItemData, user: Node):
	# 检查食物是否有有效的恢复值（value > 0）
	if item.value > 0:
		# 发射物品使用事件（用于统计、日志或其他系统监听）
		EventBus.on_inventory_used_item.emit(item)
		
		# 食物恢复体力（通过 Player 的 recover_stamina API）
		if Refs.player:
			Refs.player.recover_stamina(item.value)
			print("Applied food effect: ", item.name, " +", item.value, " Stamina")

# ------------------------------------------------------------------------------
# 函数：_handle_potion_effect
# 功能：处理药水类物品的效果（恢复生命或魔法值）
# 参数：
#   item: ItemData - 药水物品数据
#   user: Node - 使用药水的角色
# 实现逻辑：
#   1. 通过物品ID前缀判断药水类型：
#      - "hp" 或 "health" 前缀 → 生命药水
#      - "mana" 或 "mp" 前缀 → 魔法药水
#   2. 生命药水：调用HealthComponent.heal()恢复生命值
#   3. 魔法药水：调用ManaComponent.add_mana()恢复魔法值
# 设计要点：
#   - 使用ID前缀判断类型，便于扩展新药水类型
#   - 同样支持自定义使用者和降级机制
# ------------------------------------------------------------------------------
func _handle_potion_effect(item: ItemData, user: Node):
	# 判断是否为生命药水（ID以"hp"或"health"开头）
	if item.id.begins_with("hp") or item.id.begins_with("health"):
		# 恢复生命值逻辑
		var target_node: Node = null
		
		# 优先使用传入的user参数
		if user and user.has_node("HealthComponent"):
			target_node = user
		# 如果user无效，使用全局玩家引用
		elif Refs.player and Refs.player.has_node("HealthComponent"):
			target_node = Refs.player
		
		# 只有找到有效目标时才执行恢复
		if target_node:
			target_node.get_node("HealthComponent").heal(item.value)
			print("Applied health potion: ", item.name, " +", item.value, " HP")
	
	# 判断是否为魔法药水（ID以"mana"或"mp"开头）
	elif item.id.begins_with("mana") or item.id.begins_with("mp"):
		# 恢复魔法值逻辑
		# 注意：玩家的mana处理是通过player.gd中的add_mana()方法，而不是ManaComponent节点
		if user and user.has_method("add_mana"):
			user.add_mana(item.value)
			print("Applied mana potion: ", item.name, " +", item.value, " MP")
		elif Refs.player and Refs.player.has_method("add_mana"):
			Refs.player.add_mana(item.value)
			print("Applied mana potion: ", item.name, " +", item.value, " MP")
	
	# 判断是否为体力药水（ID以"stamina"开头）
	elif item.id.begins_with("stamina"):
		EventBus.on_inventory_used_item.emit(item)
		if Refs.player:
			# 提升最大体力上限
			var new_max := Refs.player.max_stamina + item.value
			Refs.player.set_max_stamina(new_max)
			# 回满体力
			Refs.player.stamina_component.recover(new_max)
			print("Applied stamina potion: ", item.name, " max_stamina +", item.value, " → ", new_max)

	# 其他类型药水的默认处理
	else:
		EventBus.on_inventory_used_item.emit(item)
		print("Applied potion effect: ", item.name)

# ------------------------------------------------------------------------------
# 函数：_handle_scroll_effect
# 功能：处理卷轴类物品的效果（释放魔法）
# 参数：
#   item: ItemData - 卷轴物品数据
#   user: Node - 使用卷轴的角色
# 实现逻辑：
#   - 当前为基础实现，仅发射事件和输出日志
#   - 可扩展为具体魔法效果（如召唤、攻击、治疗等）
# 扩展建议：
#   - 根据卷轴ID或value实现不同魔法效果
#   - 可添加范围伤害、状态效果等
# ------------------------------------------------------------------------------
func _handle_scroll_effect(item: ItemData, user: Node):
	EventBus.on_inventory_used_item.emit(item)
	print("Used scroll: ", item.name, " (Effect value: ", item.value, ")")

# ------------------------------------------------------------------------------
# 函数：_handle_ore_effect
# 功能：处理矿石类资源（不可直接使用）
# 参数：
#   item: ItemData - 矿石物品数据
#   user: Node - 尝试使用的角色
# 实现逻辑：
#   - 矿石为原材料，不能直接使用
#   - 输出提示信息告知玩家
# 设计意图：
#   - 防止玩家误操作使用不可消耗的资源
#   - 保持处理函数的完整性
# ------------------------------------------------------------------------------
func _handle_ore_effect(item: ItemData, user: Node):
	print("Cannot use ore directly: ", item.name)

# ------------------------------------------------------------------------------
# 函数：_handle_equipment_effect
# 功能：处理装备类物品（不可消耗使用）
# 参数：
#   item: ItemData - 装备物品数据
#   user: Node - 尝试使用的角色
# 实现逻辑：
#   - 装备需要通过equip_item()函数装备，不能直接消耗使用
#   - 输出提示信息告知玩家
# 设计意图：
#   - 区分装备和消耗品的使用方式
#   - 引导玩家正确使用装备系统
# ------------------------------------------------------------------------------
func _handle_equipment_effect(item: ItemData, user: Node):
	print("Equipment cannot be consumed: ", item.name)
