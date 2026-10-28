extends Resource
class_name  Item


@export var icon: Texture2D
#在检查器中显示为图片拖拽框

@export var id:String
#标识物品
@export var name:String
@export_multiline var description:String
#多行文本输入区域	物品的详细描述
@export var price :int
#数字输入框	物品的基础售价或购买价。	
