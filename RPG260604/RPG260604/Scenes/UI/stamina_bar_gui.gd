extends ProgressBar
class_name StaminaBarGUI

# 颜色方案: 按体力百分比分五档
# [fill 填充色, background 背景色(明度更低)]
const COLORS: Dictionary = {
	"green":      {fill = Color("#4CAF50"), bg = Color("#153316")},   # >= 90%
	"lightgreen": {fill = Color("#8BC34A"), bg = Color("#2E3B19")},   # >= 70%
	"yellow":     {fill = Color("#FFC107"), bg = Color("#4A3C0A")},   # >= 50%
	"red":        {fill = Color("#FF5722"), bg = Color("#3D1408")},   # >= 20%
	"deepred":    {fill = Color("#D32F2F"), bg = Color("#2D0505")},   # <  20%
}

var _fill_style: StyleBoxFlat
var _bg_style: StyleBoxFlat
var _curr_color_key: String = ""


func _ready() -> void:
	# 获取检查器中已设置的主题覆盖 StyleBox (不改结构, 只改颜色)
	var fill_sb := get_theme_stylebox("fill")
	if fill_sb is StyleBoxFlat:
		_fill_style = fill_sb
	else:
		_fill_style = StyleBoxFlat.new()
		add_theme_stylebox_override("fill", _fill_style)

	var bg_sb := get_theme_stylebox("background")
	if bg_sb is StyleBoxFlat:
		_bg_style = bg_sb
	else:
		_bg_style = StyleBoxFlat.new()
		add_theme_stylebox_override("background", _bg_style)

	# 初始默认绿色
	_apply_color("green")

	if not EventBus.on_player_stamina_updated.is_connected(_on_stamina_updated):
		EventBus.on_player_stamina_updated.connect(_on_stamina_updated)


func _on_stamina_updated(curr: float, max_val: float) -> void:
	if max_val <= 0:
		return
	var ratio := curr / max_val
	var key: String

	if ratio >= 0.9:
		key = "green"
	elif ratio >= 0.7:
		key = "lightgreen"
	elif ratio >= 0.5:
		key = "yellow"
	elif ratio >= 0.2:
		key = "red"
	else:
		key = "deepred"

	if key != _curr_color_key:
		_curr_color_key = key
		_apply_color(key)


func _apply_color(key: String) -> void:
	var c: Dictionary = COLORS[key]
	_fill_style.bg_color = c.fill
	_bg_style.bg_color = c.bg
