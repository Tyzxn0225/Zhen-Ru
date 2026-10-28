extends Node

func _ready():
	_run_tests()

func _run_tests():
	print("\n=== ITEM EFFECT TEST SUITE ===")
	
	yield(get_tree(), "idle_frame")
	
	print("\n1. Validating Resource Index...")
	get_tree().get_root().get_node("ResourceIndex").validate_all_items()
	
	print("\n2. Testing Food Items...")
	var tester = ItemEffectTester.new()
	var food_results = tester.test_all_food_items()
	
	print("\n3. Testing Potion Items...")
	var potion_items = get_tree().get_root().get_node("ResourceIndex").get_items_by_type(ItemData.Category.POTION)
	for item in potion_items:
		var result = tester.test_item(item.id)
		print(result.message)
	
	print("\n4. Testing Specific Items...")
	_test_specific_items(tester)
	
	print("\n=== TEST COMPLETE ===")

func _test_specific_items(tester: ItemEffectTester):
	var test_cases = [
		{"id": "food_beef", "expected": 3.0, "description": "牛肉恢复3点HP"},
		{"id": "food_fish", "expected": 2.0, "description": "鱼恢复2点HP"},
		{"id": "food_meat", "expected": 4.0, "description": "肉恢复4点HP"},
		{"id": "hp_potion", "expected": 2.0, "description": "生命药水恢复2点HP"}
	]
	
	for test_case in test_cases:
		var result = tester.test_item(test_case.id)
		var status = "✓" if result.success else "✗"
		print(status, " ", test_case.description)
		if not result.success:
			print("   Expected: ", test_case.expected, ", Actual: ", result.actual_value)
