# ==============================================================================
# 装备系统测试工具
# 功能：验证装备卸下功能的正确性
# 作者：系统自动生成
# 版本：1.0
# ==============================================================================
extends Node
class_name EquipmentTest

# 运行装备系统测试
func run_tests():
    print("\n=== 装备系统测试开始 ===")
    
    # 测试1：检查装备槽初始化
    test_slot_initialization()
    
    # 测试2：测试装备卸下功能
    test_unequip_function()
    
    # 测试3：测试空槽位边界情况
    test_empty_slot()
    
    # 测试4：测试重复卸下边界情况
    test_double_unequip()
    
    print("\n=== 装备系统测试完成 ===")

# 测试1：检查装备槽初始化
func test_slot_initialization():
    print("\n【测试1】装备槽初始化测试")
    
    # 获取装备面板
    var equip_panel = get_tree().get_root().find_node("EquipmentPanel", true, false)
    
    if equip_panel:
        print("  ✅ 装备面板已找到")
        
        # 检查装备槽数量
        var slot_count = len(equip_panel.slots)
        print("  装备槽数量: ", slot_count)
        
        # 检查每个槽位初始状态
        for i in range(slot_count):
            var slot = equip_panel.slots[i]
            if not slot.equipped_data:
                print("  ✅ 槽位", i, "初始为空")
            else:
                print("  ❌ 槽位", i, "初始不为空:", slot.equipped_data.name)
    else:
        print("  ❌ 装备面板未找到")

# 测试2：测试装备卸下功能
func test_unequip_function():
    print("\n【测试2】装备卸下功能测试")
    
    # 获取资源索引
    var resource_index = get_tree().get_root().get_node("ResourceIndex")
    var inventory = get_tree().get_root().get_node("Inventory")
    
    if not resource_index or not inventory:
        print("  ❌ 依赖模块未找到")
        return
    
    # 获取测试装备
    var sword = resource_index.get_item_by_id("equip_sword")
    
    if sword:
        print("  ✅ 找到测试装备: ", sword.name)
        
        # 添加装备到背包
        inventory.add_item(sword, 1)
        print("  ✅ 装备已添加到背包")
        
        # 查找装备在背包中的位置
        var slots = inventory.find_item_indexes(sword)
        if slots.size() > 0:
            # 装备物品
            inventory.equip_item(slots[0])
            print("  ✅ 装备已穿戴")
            
            # 验证装备已穿戴
            if GameData.equipement["weapon"] == sword:
                print("  ✅ 装备验证成功")
            else:
                print("  ❌ 装备验证失败")
            
            # 测试卸下（模拟右键点击）
            var equip_type = EquipData.EquipType.WEAPON
            inventory.unequip_item(equip_type)
            print("  ✅ 装备已卸下")
            
            # 验证装备已卸下
            if GameData.equipement["weapon"] == null:
                print("  ✅ 卸下验证成功")
            else:
                print("  ❌ 卸下验证失败")
        else:
            print("  ❌ 装备未找到在背包中")
    else:
        print("  ❌ 测试装备未找到")

# 测试3：测试空槽位边界情况
func test_empty_slot():
    print("\n【测试3】空槽位边界测试")
    
    var inventory = get_tree().get_root().get_node("Inventory")
    
    if not inventory:
        print("  ❌ 背包模块未找到")
        return
    
    # 尝试卸下空槽位的装备
    var equip_type = EquipData.EquipType.WEAPON
    var result = inventory.unequip_item(equip_type)  # 应该安全返回，不报错
    
    if GameData.equipement["weapon"] == null:
        print("  ✅ 空槽位卸下测试通过（无报错）")
    else:
        print("  ❌ 空槽位卸下测试失败")

# 测试4：测试重复卸下边界情况
func test_double_unequip():
    print("\n【测试4】重复卸下边界测试")
    
    var inventory = get_tree().get_root().get_node("Inventory")
    
    if not inventory:
        print("  ❌ 背包模块未找到")
        return
    
    # 连续两次卸下同一装备
    var equip_type = EquipData.EquipType.WEAPON
    inventory.unequip_item(equip_type)
    inventory.unequip_item(equip_type)  # 第二次应该安全返回
    
    print("  ✅ 重复卸下测试通过（无报错）")