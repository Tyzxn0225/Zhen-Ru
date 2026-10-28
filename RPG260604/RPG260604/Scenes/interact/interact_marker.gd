extends Node2D
class_name InteractMarker

@onready var _talk: Node2D = $talk
@onready var _portal: Node2D = $portal

var _active_pivot: Node2D
var _sprite: Sprite2D
var _highlight: Sprite2D
var _highlight_outer: Sprite2D
var _hint_style: Interactable.HintStyle = Interactable.HintStyle.TALK

var _focused: bool = false
var _quest_tracked: bool = false
var _pulse_tween: Tween

const TALK_OFFSET := Vector2(0, -29)
const PORTAL_OFFSET := Vector2(0, -16)
const BASE_SCALE := 0.171875
const FOCUSED_SCALE := 0.1953125
const HIGHLIGHT_INNER_MULT := 1.22
const HIGHLIGHT_OUTER_MULT := 1.42
const UNFOCUSED_ALPHA := 0.8
const MARKER_Z_INDEX := 100

const FOCUS_INNER_COLOR := Color(0, 0, 0, 0.85)
const FOCUS_OUTER_COLOR := Color(0, 0, 0, 0.55)
const QUEST_INNER_COLOR := Color(1, 0.88, 0.45, 0.85)
const QUEST_OUTER_COLOR := Color(1, 0.75, 0.2, 0.55)


func _ready() -> void:
	z_index = MARKER_Z_INDEX
	z_as_relative = false
	y_sort_enabled = false
	_talk.position = TALK_OFFSET
	_portal.position = PORTAL_OFFSET
	_talk.visible = false
	_portal.visible = false
	hide_hint()


## 根据可交互对象类型切换 talk / portal 分支
func configure_for(interactable: Node) -> void:
	var style := Interactable.get_hint_style(interactable)
	if style == _hint_style and _active_pivot:
		return
	_hint_style = style
	if _active_pivot:
		_active_pivot.visible = false
	_active_pivot = _talk if style == Interactable.HintStyle.TALK else _portal
	_sprite = _active_pivot.get_node_or_null("Sprite2D") as Sprite2D
	if not _sprite:
		_sprite = _active_pivot.get_node_or_null("Sprite2Dportal") as Sprite2D
	_highlight = _active_pivot.get_node("Highlight") as Sprite2D
	_highlight_outer = _active_pivot.get_node("HighlightOuter") as Sprite2D
	_apply_visual_state()


func show_hint() -> void:
	if _active_pivot:
		_active_pivot.visible = true
	visible = true


func hide_hint() -> void:
	visible = false
	set_focused(false)
	set_quest_tracked(false)
	if _talk:
		_talk.visible = false
	if _portal:
		_portal.visible = false


func set_focused(focused: bool) -> void:
	if _focused == focused:
		return
	_focused = focused
	_apply_visual_state()


func set_quest_tracked(tracked: bool) -> void:
	if _quest_tracked == tracked:
		return
	_quest_tracked = tracked
	_apply_visual_state()


func _apply_visual_state() -> void:
	if not _active_pivot or not _sprite:
		return

	_stop_pulse()

	var show_outline := _focused or _quest_tracked
	var sprite_scale := FOCUSED_SCALE if _focused else BASE_SCALE
	var scale_vec := Vector2(sprite_scale, sprite_scale)

	_sprite.scale = scale_vec
	if _focused:
		_sprite.modulate = Color(1, 1, 1, 1)
	elif _quest_tracked:
		_sprite.modulate = Color(1, 1, 1, 1)
	else:
		_sprite.modulate = Color(1, 1, 1, UNFOCUSED_ALPHA)

	if _highlight:
		_highlight.visible = show_outline
		if show_outline:
			_highlight.scale = scale_vec * HIGHLIGHT_INNER_MULT
			_highlight.modulate = FOCUS_INNER_COLOR if _focused else QUEST_INNER_COLOR

	if _highlight_outer:
		_highlight_outer.visible = show_outline
		if show_outline:
			_highlight_outer.scale = scale_vec * HIGHLIGHT_OUTER_MULT
			_highlight_outer.modulate = FOCUS_OUTER_COLOR if _focused else QUEST_OUTER_COLOR

	if _quest_tracked and not _focused:
		_start_quest_pulse(scale_vec)


func _start_quest_pulse(base_scale: Vector2) -> void:
	_stop_pulse()
	if not _highlight or not _highlight_outer:
		return
	var inner_small := base_scale * HIGHLIGHT_INNER_MULT * 0.95
	var inner_large := base_scale * HIGHLIGHT_INNER_MULT * 1.12
	var outer_small := base_scale * HIGHLIGHT_OUTER_MULT * 0.95
	var outer_large := base_scale * HIGHLIGHT_OUTER_MULT * 1.12
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_highlight, "scale", inner_large, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_highlight_outer, "scale", outer_large, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_highlight, "modulate:a", 0.55, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_highlight, "scale", inner_small, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_highlight_outer, "scale", outer_small, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_highlight, "modulate:a", 0.95, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
