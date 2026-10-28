# 物品功能实现指南

## 概述
本文档详细说明了游戏中各类物品的功能实现机制，包括脚本组件、参数配置和实现方法。

## 核心组件

### 1. ItemData (数据模型)
文件路径: `res://data/item_data.gd`

**主要属性:**
- `type`: 物品类型枚举 (FOOD, ORE, POTION, SCROLL, EQUIPMENT)
- `is_consumable`: 是否可消耗
- `max_stack`: 最大堆叠数量
- `value`: 物品效果值（如恢复血量值）

**枚举类型定义:**
```gdscript
enum Type {
    FOOD,      # 食物类 - 恢复生命值
    ORE,       # 资源类 - 用于合成
    POTION,    # 药水类 - 恢复生命/魔法
    SCROLL,    # 卷轴类 - 释放魔法
    EQUIPMENT  # 装备类 - 穿戴属性
}
```

### 2. ItemEffectHandler (效果处理器)
文件路径: `res://autoloads/item_effect_handler.gd`

**功能:**
- 注册和管理各类物品的效果处理函数
- 应用物品效果到目标对象

**使用方法:**
```gdscript
# 使用物品
ItemEffectHandler.apply_item_effect(item, user_node)
```

### 3. ResourceIndex (资源索引)
文件路径: `res://autoloads/resource_index.gd`

**功能:**
- 自动扫描并索引所有.tres资源文件
- 提供按ID、类型、分类查询物品的接口

**使用方法:**
```gdscript
# 根据ID获取物品
var item = ResourceIndex.get_item_by_id("food_beef")

# 获取所有食物类物品
var foods = ResourceIndex.get_items_by_type(ItemData.Type.FOOD)

# 验证所有物品
var validation = ResourceIndex.validate_all_items()
```

## 各类物品功能实现

### 食物类 (FOOD)

**功能:** 恢复玩家生命值

**配置参数:**
- `type`: `ItemData.Type.FOOD`
- `is_consumable`: `true`
- `value`: 恢复的血量值 (如 3.0)
- `max_stack`: 堆叠数量

**效果实现:**
```gdscript
func _handle_food_effect(item: ItemData, user: Node):
    if item.value > 0:
        EventBus.on_inventory_used_item.emit(item)
        if user and user.has_node("HealthComponent"):
            var health_component = user.get_node("HealthComponent")
            health_component.heal(item.value)
```

**示例配置 (.tres文件):**
```
[gd_resource type="Resource" script_class="ItemData" format=3]
[ext_resource type="Script" path="res://data/item_data.gd" id="1"]
[ext_resource type="Texture2D" path="res://Sprites/Items/Food/Beef.png" id="2"]

[resource]
script = ExtResource("1")
type = 0          # FOOD
is_consumable = true
value = 3.0       # 恢复3点生命值
max_stack = 20
icon = ExtResource("2")
id = "food_beef"
name = "牛肉"
description = "鲜嫩的烤牛肉，恢复3点生命值。"
price = 10
```

### 药水类 (POTION)

**功能:** 恢复生命值或魔法值

**配置参数:**
- `type`: `ItemData.Type.POTION`
- `is_consumable`: `true`
- `value`: 恢复值
- `max_stack`: 堆叠数量
- `id`: 必须以 "hp_" 或 "mana_" 开头

**效果实现:**
```gdscript
func _handle_potion_effect(item: ItemData, user: Node):
    if item.id.begins_with("hp") or item.id.begins_with("health"):
        user.get_node("HealthComponent").heal(item.value)
    elif item.id.begins_with("mana") or item.id.begins_with("mp"):
        user.get_node("ManaComponent").add_mana(item.value)
```

### 卷轴类 (SCROLL)

**功能:** 释放魔法攻击或特殊效果

**配置参数:**
- `type`: `ItemData.Type.SCROLL`
- `is_consumable`: `true`
- `value`: 魔法伤害值

### 资源类 (ORE)

**功能:** 用于合成和交易，不可直接使用

**配置参数:**
- `type`: `ItemData.Type.ORE`
- `is_consumable`: `false`

### 装备类 (EQUIPMENT)

**功能:** 穿戴后提供属性加成，不可消耗

**配置参数:**
- `type`: `ItemData.Type.EQUIPMENT`
- `is_consumable`: `false`
- 使用 `EquipData` 扩展类

## 测试验证

### ItemEffectTester (测试工具)
文件路径: `res://tools/item_effect_tester.gd`

**使用方法:**
```gdscript
# 测试单个物品
var result = ItemEffectTester.test_item("food_beef")

# 测试所有食物物品
var results = ItemEffectTester.test_all_food_items()

# 验证资源索引
ItemEffectTester.validate_resource_index()
```

**测试结果格式:**
```gdscript
{
    success: bool,
    item_id: String,
    item_name: String,
    effect_type: String,
    expected_value: float,
    actual_value: float,
    message: String
}
```

## 最佳实践

### 命名规范
- 文件命名: `item_<category>_<name>.tres`
  - 示例: `item_food_beef.tres`, `item_potion_hp_small.tres`
- ID命名: `<category>_<name>`
  - 示例: `food_beef`, `potion_hp_small`

### 分类目录结构
```
data/
├── food/          # 食物类
├── potions/       # 药水类
├── equipment/     # 装备类
├── resources/     # 资源类
├── scrolls/       # 卷轴类
├── treasures/     # 宝藏类
├── tools/         # 工具类
└── projectiles/   # 弹药类
```

### 创建新物品流程
1. 在对应的分类目录下创建 `.tres` 文件
2. 设置正确的 `type` 枚举值
3. 配置 `is_consumable` 和 `value` 属性
4. 添加图标和描述信息
5. 运行测试验证功能

## 常见问题

### Q: 物品使用后没有效果？
**检查项:**
1. 确认 `is_consumable` 设置为 `true`
2. 确认 `type` 设置正确
3. 确认 `value` 值大于 0
4. 确认玩家节点有 `HealthComponent`

### Q: 资源索引找不到物品？
**检查项:**
1. 确认文件扩展名为 `.tres`
2. 确认文件放置在 `data/` 目录下
3. 确认物品 `id` 属性已设置
4. 检查是否有重复的 `id`

### Q: 物品无法堆叠？
**检查项:**
1. 确认 `max_stack` 值大于 0
2. 确认同类物品的 `id` 完全相同

## 更新日志

### v1.0
- 实现食物类血量恢复功能
- 创建物品效果处理器
- 建立资源索引系统
- 添加测试验证工具