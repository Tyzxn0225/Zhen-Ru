class_name BalloonTestDialogue
extends RefCounted
## 对话测试键：8 倍速 + 自动跳下一句（多选项分支仍暂停）。可整文件删除。


const SPEED_MULT := 8.0

var _balloon: Node
var _enabled: bool = false
var _saved_seconds_per_step: float = -1.0


func _init(balloon: Node) -> void:
	_balloon = balloon


func handle_input(event: InputEvent) -> bool:
	if not TestKey.is_just_pressed(event):
		return false
	set_enabled(not _enabled)
	if _enabled:
		var line: DialogueLine = _balloon.get("dialogue_line")
		if line != null:
			try_auto_continue(line)
	return true


func set_enabled(value: bool) -> void:
	_enabled = value
	var label: DialogueLabel = _balloon.get("dialogue_label")
	if label == null:
		return
	if _saved_seconds_per_step < 0.0:
		_saved_seconds_per_step = label.seconds_per_step
	label.seconds_per_step = _saved_seconds_per_step / SPEED_MULT if _enabled else _saved_seconds_per_step


func is_enabled() -> bool:
	return _enabled


func scaled_timed_wait(base_seconds: float) -> float:
	return base_seconds / SPEED_MULT if _enabled else base_seconds


func should_show_response_menu(responses: Array) -> bool:
	if not _enabled:
		return responses.size() > 0
	return count_allowed_responses(responses) > 1


func try_auto_continue(line: DialogueLine) -> bool:
	if not _enabled or line == null:
		return false
	var allowed := count_allowed_responses(line.responses)
	if allowed > 1:
		return false
	var next_id := line.next_id
	if allowed == 1:
		next_id = first_allowed_response(line.responses).next_id
	if next_id.is_empty():
		return false
	_balloon.call("next", next_id)
	return true


static func count_allowed_responses(responses: Array) -> int:
	var count := 0
	for response in responses:
		if response.is_allowed:
			count += 1
	return count


static func first_allowed_response(responses: Array) -> DialogueResponse:
	for response in responses:
		if response.is_allowed:
			return response
	return responses[0] as DialogueResponse
