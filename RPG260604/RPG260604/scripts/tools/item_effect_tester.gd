extends Node
class_name ItemEffectTester

func test_item(item_id: String, simulate_user: Node = null) -> Dictionary:
    var result = {
        success = false,
        item_id = item_id,
        item_name = "",
        effect_type = "",
        expected_value = 0,
        actual_value = 0,
        message = ""
    }
    
    var item = get_tree().get_root().get_node("ResourceIndex").get_item_by_id(item_id)
    if not item:
        result.message = "Item not found: " + item_id
        return result
    
    result.item_name = item.name
    result.effect_type = str(item.category)
    result.expected_value = item.value
    
    if not item.is_consumable:
        result.message = "Item is not consumable: " + item.name
        result.success = true
        return result
    
    var test_player = _create_test_player()
    
    var initial_health = test_player.get_node("HealthComponent").curr_health
    get_tree().get_root().get_node("ItemEffectHandler").apply_item_effect(item, test_player)
    var final_health = test_player.get_node("HealthComponent").curr_health
    
    var health_gained = final_health - initial_health
    
    if item.category == ItemData.Category.FOOD or item.category == ItemData.Category.POTION:
        if health_gained == item.value:
            result.success = true
            result.actual_value = health_gained
            result.message = "SUCCESS: " + item.name + " restored " + str(health_gained) + " HP (expected: " + str(item.value) + ")"
        else:
            result.success = false
            result.actual_value = health_gained
            result.message = "FAILED: " + item.name + " restored " + str(health_gained) + " HP (expected: " + str(item.value) + ")"
    else:
        result.success = true
        result.message = "Item type does not restore health: " + str(item.type)
    
    return result

func _create_test_player() -> Node:
    var test_player = Node.new()
    test_player.name = "TestPlayer"
    
    var health_component = HealthComponent.new()
    health_component.max_health = 100.0
    health_component.curr_health = 50.0
    test_player.add_child(health_component)
    
    return test_player

func test_all_food_items() -> Array:
    var results = []
    var food_items = get_tree().get_root().get_node("ResourceIndex").get_items_by_type(ItemData.Category.FOOD)
    
    print("\n=== Testing All Food Items ===")
    
    for item in food_items:
        var result = test_item(item.id)
        results.append(result)
        print(result.message)
    
    var success_count = 0
    for r in results:
        if r.success:
            success_count += 1
    print("Test Results: ", success_count, "/", results.size(), " passed")
    print("============================\n")
    
    return results

func test_all_items() -> Array:
    var results = []
    var all_items = get_tree().get_root().get_node("ResourceIndex").get_all_items()
    
    print("\n=== Testing All Items ===")
    
    for item in all_items:
        var result = test_item(item.id)
        results.append(result)
    
    var success_count = 0
    for r in results:
        if r.success:
            success_count += 1
    print("Test Results: ", success_count, "/", results.size(), " passed")
    print("============================\n")
    
    return results

func validate_resource_index() -> void:
    print("\n=== Validating Resource Index ===")
    var validation = get_tree().get_root().get_node("ResourceIndex").validate_all_items()
    
    print("Valid items: ", validation.valid)
    print("Invalid items: ", validation.invalid)
    
    if validation.errors.size() > 0:
        print("\nErrors:")
        for error in validation.errors:
            print("  - ", error)
    
    if validation.warnings.size() > 0:
        print("\nWarnings:")
        for warning in validation.warnings:
            print("  - ", warning)
    
    print("============================\n")
