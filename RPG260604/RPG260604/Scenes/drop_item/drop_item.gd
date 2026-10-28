extends Area2D
class_name DropItem

@export var item : ItemData
@export var amount:int =1
#掉落数量，默认为 1。
@export var shine_speed :=0.6
#扫光动画速度（秒）。数值越小，扫光移动越快。
@export var shine_freq : =1.0
#两次扫光之间的间隔时间（秒）。
@onready var sprite: Sprite2D = $Sprite
#在 _ready() 执行前自动获取子节点 Sprite，用于显示物品图标。
func _ready() -> void:
	setup()
	shine_item()
	
func setup()->void:
	if item and item.icon:
		sprite.texture = item.icon
#将 Sprite2D 显示的图片设置为物品图标。
func load_item(data:SlotData)->void:
	item = data.item
	amount = data.quantity
#动态设置物品类型和数量
func shine_item()->void:
	var shine_tween : = create_tween().set_loops()
	#创建一个 Tween 对象，并调用 set_loops()（无参数表示无限循环）。
	shine_tween.tween_property(sprite.material,"shader_parameter/shine_progress",1.0,shine_speed).set_delay(shine_freq)
	shine_tween.tween_property(sprite.material,"shader_parameter/shine_progress",0.0,0.0)
#sprite.material：必须是一个 ShaderMaterial，且其着色器含有 uniform float shine_progress。
#属性路径："shader_parameter/参数名" 是 Godot 4 访问着色器参数的标准格式。
#目标值 1.0：将扫光进度推到最右侧（完全扫过）。
#时长 shine_speed：扫光从当前位置移动到目标位置所需的时间。
#.set_delay(shine_freq)：在本次动画开始前等待 shine_freq 秒，实现扫光之间的停顿。


func _on_body_entered(body: Node2D) -> void:
	Inventory.add_item(item,amount)
	queue_free()
	#删除自身
