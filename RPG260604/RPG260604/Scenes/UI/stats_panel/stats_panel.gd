extends PanelContainer
class_name  statspanel
@onready var damage_label: Label = %DamageLabel
@onready var hp_label_2: Label = %HpLabel2
@onready var vell_label: Label = %VellLabel
@onready var mana_label_2: Label = %ManaLabel2
@onready var crit_label: Label = %CritLabel
@onready var crit_dmg_label_2: Label = %CritDMGLabel2

@onready var curr_level_label: Label = %CurrLevelLabel
@onready var cur_point_label: Label = %CurPointLabel

@onready var str_points_label: Label = %STRPointsLabel
@onready var dex_points_label: Label = %DEXPointsLabel
@onready var int_points_label: Label = %INTPointsLabel

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_str_button_pressed() -> void:
	pass # Replace with function body.


func _on_dex_button_pressed() -> void:
	pass # Replace with function body.


func _on_int_button_pressed() -> void:
	pass # Replace with function body.
