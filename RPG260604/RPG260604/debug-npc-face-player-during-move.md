# Debug Session: npc-face-player-during-move

## Session ID
`npc-face-player-during-move`

## Bug Description
在对话脚本 `测试 入学.dialogue` 中，执行到"学长再见"后调用 `do Refs.current_npc.move_waypoints([Vector2(96, -100), Vector2(96, -480)], 80)` 时：
- ✅ NPC 人物正常移动
- ❌ 当快速完成对话，对话框消失后，NPC 立即朝向玩家
- ❌ 即使移动还没完成也会立即转向玩家

## Root Cause (CONFIRMED)

### 问题位置: `npc.gd` `_on_dialogue_input_blocked()` 函数的逻辑分支

**原代码**：
```gdscript
if can_move and not _in_story_movement:
    _movement_paused = false        # 恢复移动
else:
    # 非移动 NPC: 恢复到交互前的朝向
    if face_player_on_interact and not _pre_interact_direction.is_empty():
        last_direction = _pre_interact_direction
        play_animation("idle")
    _pre_interact_direction = ""
```

**问题分析**：
NPC `can_move = true` (默认值), `_in_story_movement = true` (故事移动未完成)
- 条件 `can_move and not _in_story_movement` = `true and false` = `false`
- **进入 else 分支**：恢复交互前的朝向 = 玩家方向
- **播放 idle 动画** → NPC 立即朝向玩家 ❌

## Fix Applied

修改 `e:\AAA big one\A godot\MY DEMO\RPG260531\Scenes\npc\npc.gd` 中 `_on_dialogue_input_blocked()` 函数：

```gdscript
# 故事移动进行中: 不要恢复交互前朝向, 也不要解锁 _movement_paused
# 保持当前移动状态, 等故事移动完成时由 _on_story_move_complete 统一处理
if _in_story_movement:
    _movement_paused = true
    _pre_interact_direction = ""
    return

if can_move:
    _movement_paused = false
else:
    # 非移动 NPC: 恢复到交互前的朝向
    if face_player_on_interact and not _pre_interact_direction.is_empty():
        last_direction = _pre_interact_direction
        play_animation("idle")
_pre_interact_direction = ""
```

**修复逻辑**：
1. **故事移动进行中** (`_in_story_movement = true`)：保持 `_movement_paused = true`，不恢复朝向，让故事移动自然完成
2. 故事移动完成时，由 `_on_story_move_complete()` 统一处理：解锁移动并播放 idle
3. **非故事移动 + 可移动** (`can_move = true`)：解锁移动，由 `_process()` 接管
4. **不可移动** (`can_move = false`)：恢复到交互前的朝向

## Status

**[FIXED]** - Root cause identified and minimal fix applied.

## Verification Required
请用户验证：
- ✅ 对话快速结束后，NPC 继续移动而不立即转向玩家
- ✅ 移动完成后，NPC 解锁自动移动
- ✅ 普通对话（非故事移动）行为不变
