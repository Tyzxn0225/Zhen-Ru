extends Item
class_name ItemData

## 物品类型: 收藏品 (堆叠上限 1) / 消耗品 (堆叠上限 64)
enum Type { COLLECTIBLE, CONSUMABLE }

## 物品品类: 决定效果处理方式 (食物恢复HP / 药水恢复HP或MP / 卷轴施法 / 矿石原材料 / 装备)
enum Category { FOOD, POTION, ORE, SCROLL, EQUIPMENT }

@export var type: Type
@export var category: Category

## 是否可消耗
@export var is_consumable: bool = false

## 最大堆叠数
@export var max_stack: int = 1

@export_group("consumable")
@export var value: float
