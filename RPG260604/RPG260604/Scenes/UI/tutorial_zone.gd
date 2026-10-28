# tutorial_zone.gd
extends Area2D

@export var title: String = "教程"
@export var hint: String = "按 E 学习技能"

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(_area: Area2D) -> void:
	UIManager.show_custom_hint(title, hint)

func _on_area_exited(_area: Area2D) -> void:
	UIManager.hide_custom_hint()
