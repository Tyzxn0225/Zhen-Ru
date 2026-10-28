extends SubViewport
## 大地图专用 SubViewport：共享主世界，相机由 WorldMapPanel 手动控制。


func _ready() -> void:
	world_2d = get_tree().root.world_2d
	get_tree().root.set_canvas_cull_mask_bit(1, false)
