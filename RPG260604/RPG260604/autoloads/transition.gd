extends Node

@onready var color_rect: ColorRect = %ColorRect


var tween: Tween

func _ready() -> void:
	if not color_rect:
		color_rect = get_node("%ColorRect")


func fade_in(duration: float = 0.5) -> void:
	if tween:
		tween.kill()
	
	color_rect.material.set_shader_parameter("progress", 0.0)
	tween = create_tween()
	tween.tween_property(color_rect.material, "shader_parameter/progress", 1.0, duration)
	await tween.finished

func fade_out(duration: float = 0.5) -> void:
	if tween:
		tween.kill()
	
	color_rect.material.set_shader_parameter("progress", 1.0)
	tween = create_tween()
	tween.tween_property(color_rect.material, "shader_parameter/progress", 0.0, duration)
	await tween.finished
