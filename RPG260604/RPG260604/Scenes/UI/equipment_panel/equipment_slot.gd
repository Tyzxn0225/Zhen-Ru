extends Button
class_name EquipmentSlot

# ==============================================================================
# 信号定义
# ==============================================================================

# 【信号】装备槽被点击时触发
# 参数：equip_type - 装备类型，button - 鼠标按钮（1=左键，2=右键），slot - 槽位引用
signal on_slot_clicked(equip_type: EquipData.EquipType, button: int, slot: EquipmentSlot)

# ==============================================================================
# 成员变量
# ==============================================================================

@export var equip_type: EquipData.EquipType
@onready var item_icon: TextureRect = $ItemIcon
@onready var selector: TextureRect = $Selector

var equipped_data: EquipData

# ==============================================================================
# 生命周期函数
# ==============================================================================

func _ready() -> void:
	clear_slot()
	# 连接信号到事件处理函数
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# ==============================================================================
# 数据加载函数
# ==============================================================================

func load_data(data: EquipData) -> void:
	equipped_data = data
	if data:
		item_icon.texture = data.icon
		item_icon.show()
		item_icon.modulate = Color.WHITE
	else:
		clear_slot()

func clear_slot() -> void:
	equipped_data = null
	item_icon.texture = null
	item_icon.hide()

# ==============================================================================
# 鼠标事件处理
# ==============================================================================

# 【鼠标进入事件】显示选择高亮
func _on_mouse_entered() -> void:
	if equipped_data:
		selector.show()

# 【鼠标离开事件】隐藏选择高亮
func _on_mouse_exited() -> void:
	selector.hide()

# 【GUI输入事件】处理鼠标点击
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键点击触发卸下
			on_slot_clicked.emit(equip_type, MOUSE_BUTTON_RIGHT, self)
			# 只有当有装备时才播放动画
			if equipped_data:
				_play_unequip_animation()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# 左键点击查看详情
			on_slot_clicked.emit(equip_type, MOUSE_BUTTON_LEFT, self)

# ==============================================================================
# 视觉反馈函数
# ==============================================================================

# 播放卸下动画
func _play_unequip_animation() -> void:
	var tween = create_tween()
	tween.tween_property(item_icon, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(item_icon, "modulate", Color.WHITE, 0.1)
	tween.set_trans(Tween.TRANS_LINEAR)

# ==============================================================================
# 调试函数
# ==============================================================================

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
