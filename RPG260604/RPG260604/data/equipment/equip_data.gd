extends ItemData
class_name EquipData

enum EquipType{
	HELMET,BODY,LEGS,WEAPON,RING
}

@export var equip_type:EquipType

# 【特殊装备属性】
# 是否任务绑定装备（任务期间无法卸下）
@export var is_quest_bounded: bool = false

# 是否无法卸下（永久绑定装备）
@export var cannot_unequip: bool = false

func  _init() -> void:
	type = Type.COLLECTIBLE
	
func get_equip_key()->String:
	match equip_type:
		EquipType.HELMET:return "helmet"
		EquipType.BODY:return "body"
		EquipType.LEGS:return "legs"
		EquipType.WEAPON:return "weapon"
		EquipType.RING:return "ring"
	return ""

static func equip_type_to_string(equip_type: EquipType) -> String:
	match equip_type:
		EquipType.HELMET:return "helmet"
		EquipType.BODY:return "body"
		EquipType.LEGS:return "legs"
		EquipType.WEAPON:return "weapon"
		EquipType.RING:return "ring"
	return ""
