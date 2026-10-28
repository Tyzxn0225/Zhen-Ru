extends Node
class_name FSM

signal on_state_transitioned(state_name:String)


@export var initial_state: NodePath

var curr_state : State


func _ready() -> void:
	#节点的生命周期回调，它只在节点首次进入场景树时由引擎自动调用一次
	await  owner.ready
	for state:State in get_children():
		state.fsm = self
	#为子节点（状态）的fsm变量调用自己，对应var fsm: FSM
	#对应的state（子节点们）引用(不是复制，而是可以使用)了整个FSM对象（节点本身），而不是单独某个函数
	curr_state =get_node(initial_state)
	curr_state.enter_state()
	#获取初始状态，并启用其enter_state函数
	
	
func transition_to(state_name:String)-> void:
	#定义  转换状态 的函数
	if not has_node(state_name):
		return
	#如果当前节点下不存在名为state_name的子节点，则直接退出函数。
	#如idel转换为run状态时，检查是否存在名为 "Run" 的子节点。存在时继续
	curr_state.exit_state()
	#如果继续，使旧状态结束，调用旧状态的 exit_state() 方法。
	curr_state = get_node(state_name)
	#获取目标状态节点，并将其设置为当前状态。
	curr_state.enter_state()
	#使新状态开始，调用新状态的 enter_state() 方法。
	on_state_transitioned.emit(curr_state.name)
	#发射信号，并附上新状态的节点名称。
