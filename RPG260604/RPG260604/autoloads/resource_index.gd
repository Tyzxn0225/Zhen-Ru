# ==============================================================================
# 资源索引系统 (ResourceIndex)
# 功能概述：自动扫描、索引和管理所有游戏物品资源
# 设计模式：单例模式 + 工厂模式（隐式）
# 核心机制：游戏启动时自动扫描data目录，将所有.tres资源加载到内存索引中
# 作者：系统自动生成
# 版本：1.0
# ==============================================================================
extends Node
class_name ResourceIndex

# ==============================================================================
# 成员变量定义
# ==============================================================================

# 【核心数据结构】物品总表
# 作用：存储所有已注册的物品数据，支持快速查找
# 数据格式：Dictionary<String, ItemData>
#   - Key: 物品唯一ID（如"food_beef", "potion_hp_small"）
#   - Value: 物品数据对象（ItemData类型）
# 访问方式：items["food_beef"] → 获取牛肉物品数据
var items: Dictionary = {}

# 【核心数据结构】按类型分组的物品列表
# 作用：按物品类型分类存储，便于批量查询
# 数据格式：Dictionary<int, Array<ItemData>>
#   - Key: ItemData.Category 枚举值（FOOD=0, ORE=1, POTION=2, SCROLL=3, EQUIPMENT=4）
#   - Value: 对应类型的物品数组
# 访问方式：items_by_type[ItemData.Category.FOOD] → 获取所有食物物品
var items_by_type: Dictionary = {}

# 【核心数据结构】按目录分类分组的物品列表
# 作用：按文件目录分类存储，便于按功能模块管理
# 数据格式：Dictionary<String, Array<ItemData>>
#   - Key: 目录名称（如"food", "potions", "equipment", "ore"）
#   - Value: 对应目录的物品数组
# 访问方式：items_by_category["food"] → 获取food目录下的所有物品
var items_by_category: Dictionary = {}

# ==============================================================================
# 生命周期函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：_ready
# 触发时机：节点添加到场景树时自动调用
# 功能：初始化索引系统，启动资源扫描流程
# ------------------------------------------------------------------------------
func _ready():
	_initialize_index()

# ==============================================================================
# 私有初始化函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：_initialize_index
# 功能：初始化索引系统的数据结构并启动资源扫描
# 执行流程：
#   1. 清空旧数据 → 2. 初始化类型分组 → 3. 启动目录扫描
# 设计要点：
#   - 在游戏启动时自动执行，确保所有资源在游戏开始前已加载完成
#   - 支持热更新场景下的重新初始化
# ------------------------------------------------------------------------------
func _initialize_index():
	# 清空旧数据，确保索引干净（防止重复加载）
	items = {}
	
	# 初始化类型分组，预定义所有支持的物品类型
	# ItemData.Category 枚举定义：
	#   FOOD = 0      - 食物类
	#   ORE = 1       - 资源/矿石类
	#   POTION = 2    - 药水类
	#   SCROLL = 3    - 卷轴类
	#   EQUIPMENT = 4 - 装备类
	items_by_type = {
		ItemData.Category.FOOD: [],      # 食物类型
		ItemData.Category.ORE: [],       # 资源/矿石类型
		ItemData.Category.POTION: [],    # 药水类型
		ItemData.Category.SCROLL: [],    # 卷轴类型
		ItemData.Category.EQUIPMENT: []  # 装备类型
	}
	
	# 初始化分类分组（按目录名）
	items_by_category = {}
	
	# 启动资源目录扫描，从res://data目录开始递归扫描
	_scan_resource_directory("res://data")

# ==============================================================================
# 私有扫描与注册函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：_scan_resource_directory
# 功能：递归扫描指定目录下的所有.tres资源文件
# 参数：
#   path: String - 要扫描的目录路径（如"res://data", "res://data/food"）
# 执行流程：
#   1. 打开目录 → 2. 遍历文件列表 → 3. 递归扫描子目录 → 4. 注册资源文件
# 错误处理：
#   - 目录打开失败时输出错误日志并返回
# ------------------------------------------------------------------------------
func _scan_resource_directory(path: String):
	# 尝试打开目录，获取目录访问对象
	var dir = DirAccess.open(path)
	if not dir:
		print("Error: Could not open directory: ", path)
		return
	
	# 开始遍历目录内容
	dir.list_dir_begin()
	# 获取第一个文件/目录名称
	var file_name = dir.get_next()
	
	# 循环遍历所有文件和目录
	while file_name != "":
		if dir.current_is_dir():
			# 如果是目录，递归扫描子目录
			_scan_resource_directory(path + "/" + file_name)
		elif file_name.ends_with(".tres"):
			# 如果是.tres资源文件，注册到索引
			_register_resource(path + "/" + file_name)
		
		# 获取下一个文件/目录
		file_name = dir.get_next()
	
	# 结束目录遍历
	dir.list_dir_end()

# ------------------------------------------------------------------------------
# 函数：_register_resource
# 功能：将单个资源文件注册到索引系统
# 参数：
#   resource_path: String - 资源文件的完整路径（如"res://data/food/item_food_beef.tres"）
# 执行流程：
#   1. 加载资源 → 2. 类型检查 → 3. 去重检查 → 4. 多维度索引
# 设计要点：
#   - 支持ItemData及其子类（如EquipData）
#   - 自动处理重复ID冲突
#   - 同时维护三种索引结构（总表、类型分组、目录分组）
# ------------------------------------------------------------------------------
func _register_resource(resource_path: String):
	# 尝试加载资源文件（使用load函数异步加载）
	var resource = load(resource_path)
	if not resource:
		print("Warning: Could not load resource: ", resource_path)
		return
	
	# 只处理ItemData类型的资源（包括其子类如EquipData）
	if resource is ItemData:
		var item = resource
		
		# 【去重检查】检查物品ID是否已存在，防止重复注册
		if item.id in items:
			print("Warning: Duplicate item ID detected: ", item.id)
			return
		
		# 1. 添加到物品总表（按ID索引）
		items[item.id] = item
		
		# 2. 添加到类型分组（按 ItemData.Category 索引）
		if item.category in items_by_type:
			items_by_type[item.category].append(item)
		
		# 3. 添加到目录分类分组（按目录名索引）
		var category = _get_category_from_path(resource_path)
		if category not in items_by_category:
			items_by_category[category] = []
		items_by_category[category].append(item)
		
		# 输出注册日志（开发调试用）
		print("Registered item: ", item.id, " -> ", item.name)

# ------------------------------------------------------------------------------
# 函数：_get_category_from_path
# 功能：从资源路径中提取分类名称
# 参数：
#   path: String - 资源文件路径（如"res://data/food/item_food_beef.tres"）
# 返回值：String - 分类名称（如"food", "potions"）
# 实现逻辑：
#   路径格式示例："res://data/food/item_food_beef.tres"
#   按"/"分割后，倒数第二部分即为目录名（分类名称）
#   分割结果：["res:", "", "data", "food", "item_food_beef.tres"]
#   倒数第二元素："food"
# ------------------------------------------------------------------------------
func _get_category_from_path(path: String) -> String:
	var parts = path.split("/")
	if parts.size() >= 3:
		var category = parts[parts.size() - 2]
		return category
	return "other"

# ==============================================================================
# 公共查询函数（API接口）
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：get_item_by_id
# 功能：根据物品ID获取物品数据
# 参数：
#   item_id: String - 物品唯一标识（如"food_beef"）
# 返回值：ItemData - 对应的物品数据（不存在时返回null）
# 使用场景：
#   - 通过ID快速查找物品
#   - 从配置文件或数据库中加载物品后查找详细信息
# ------------------------------------------------------------------------------
func get_item_by_id(item_id: String) -> ItemData:
	return items.get(item_id)

# ------------------------------------------------------------------------------
# 函数：get_items_by_type
# 功能：根据物品类型获取物品列表
# 参数：
#   item_type: int - ItemData.Category枚举值（FOOD=0, ORE=1, POTION=2, SCROLL=3, EQUIPMENT=4）
# 返回值：Array<ItemData> - 对应类型的物品数组（不存在时返回空数组）
# 使用场景：
#   - 获取所有食物/药水/装备等
#   - 按类型筛选物品
# ------------------------------------------------------------------------------
func get_items_by_type(item_type: int) -> Array:
	return items_by_type.get(item_type, [])

# ------------------------------------------------------------------------------
# 函数：get_items_by_category
# 功能：根据目录分类获取物品列表
# 参数：
#   category: String - 分类名称（如"food", "potions", "equipment"）
# 返回值：Array<ItemData> - 对应分类的物品数组（不存在时返回空数组）
# 使用场景：
#   - 获取某个目录下的所有物品
#   - 按功能模块组织物品
# ------------------------------------------------------------------------------
func get_items_by_category(category: String) -> Array:
	return items_by_category.get(category, [])

# ------------------------------------------------------------------------------
# 函数：has_item
# 功能：检查物品是否存在于索引中
# 参数：
#   item_id: String - 物品唯一标识
# 返回值：bool - 存在返回true，否则返回false
# 使用场景：
#   - 验证物品ID是否有效
#   - 在使用物品前检查是否存在
# ------------------------------------------------------------------------------
func has_item(item_id: String) -> bool:
	return item_id in items

# ------------------------------------------------------------------------------
# 函数：get_all_items
# 功能：获取所有已注册的物品列表
# 返回值：Array<ItemData> - 所有物品数据数组
# 使用场景：
#   - 遍历所有物品进行批量操作
#   - 生成物品列表UI
# ------------------------------------------------------------------------------
func get_all_items() -> Array:
	return items.values()

# ==============================================================================
# 验证函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：validate_all_items
# 功能：验证所有已注册物品的配置正确性
# 返回值：Dictionary - 验证结果
# 结果结构：
#   valid: int - 有效物品数量
#   invalid: int - 无效物品数量
#   errors: Array - 错误信息列表（严重问题，如缺少ID）
#   warnings: Array - 警告信息列表（轻微问题，如缺少名称）
# 使用场景：
#   - 游戏启动时自动验证资源配置
#   - 开发阶段检查资源完整性
# ------------------------------------------------------------------------------
func validate_all_items() -> Dictionary:
	var results = {
		valid = 0,       # 有效物品计数
		invalid = 0,     # 无效物品计数
		errors = [],     # 错误列表（严重问题）
		warnings = []    # 警告列表（轻微问题）
	}
	
	# 遍历所有物品进行验证
	for item_id in items:
		var item = items[item_id]
		var validation = _validate_item(item)
		
		if validation.valid:
			results.valid += 1
			if validation.warnings:
				results.warnings.append(validation.warnings)
		else:
			results.invalid += 1
			results.errors.append(validation.errors)
	
	return results

# ------------------------------------------------------------------------------
# 函数：_validate_item
# 功能：验证单个物品的配置正确性
# 参数：
#   item: ItemData - 要验证的物品数据
# 返回值：Dictionary - 验证结果
# 验证规则：
#   1. 必需字段检查：物品ID不能为空
#   2. 建议字段检查：物品名称建议填写
#   3. 逻辑检查：食物应该是可消耗的且有正的恢复值
#   4. 逻辑检查：可消耗物品应该有有效的最大堆叠数
# ------------------------------------------------------------------------------
func _validate_item(item: ItemData) -> Dictionary:
	var result = {
		valid = true,    # 是否有效
		errors = [],     # 错误列表
		warnings = []    # 警告列表
	}
	
	# 【必需字段检查】物品ID不能为空
	if not item.id or item.id.is_empty():
		result.valid = false
		result.errors.append("Item has no ID: " + str(item.name))
	
	# 【建议字段检查】物品名称建议填写
	if not item.name or item.name.is_empty():
		result.warnings.append("Item has no name: " + str(item.id))
	
	# 【逻辑检查】食物类型应该是可消耗的
	if item.category == ItemData.Category.FOOD and not item.is_consumable:
		result.warnings.append("Food item is not consumable: " + item.id)
	
	# 【逻辑检查】食物类型应该有正的恢复值
	if item.category == ItemData.Category.FOOD and item.value <= 0:
		result.warnings.append("Food item has non-positive value: " + item.id)
	
	# 【逻辑检查】可消耗物品应该有有效的最大堆叠数
	if item.is_consumable and item.max_stack <= 0:
		result.warnings.append("Consumable item has invalid max_stack: " + item.id)
	
	return result

# ==============================================================================
# 调试函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数：debug_print_index
# 功能：输出索引系统的调试信息
# 用途：
#   - 开发阶段快速查看索引状态
#   - 验证资源加载是否正确
#   - 检查物品数量统计
# 输出格式：
#   - 总物品数
#   - 按类型分组的物品数
#   - 按目录分组的物品数
# ------------------------------------------------------------------------------
func debug_print_index():
	print("\n=== Resource Index Report ===")
	print("Total items registered: ", items.size())
	
	# 按类型输出统计
	for type_name in [ItemData.Category.FOOD, ItemData.Category.ORE, ItemData.Category.POTION, ItemData.Category.SCROLL, ItemData.Category.EQUIPMENT]:
		var type_items = items_by_type.get(type_name, [])
		print("  ", type_name, ": ", type_items.size(), " items")
	
	# 按分类输出统计
	print("\nCategories:")
	for category in items_by_category:
		print("  ", category, ": ", items_by_category[category].size(), " items")
	
	print("============================\n")
