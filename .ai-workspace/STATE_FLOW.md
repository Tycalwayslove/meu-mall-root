# 统一状态流转

## 状态枚举

```text
idea -> draft -> ready -> in_progress -> implemented -> verified -> released -> archived
                         \-> blocked
```

## 状态定义

### idea

只是想法。可以讨论价值、方向和拆分方式，不允许实现。

### draft

需求正在整理。目标、范围、接口或验收仍不完整，不允许实现。

### ready

可以开发。必须满足：

- 目标明确。
- 范围明确。
- 责任边界明确。
- 验收标准明确。
- 验证命令明确。
- 跨项目契约已定义或确认无影响。

### in_progress

正在实现。AI 必须维护任务记录，说明当前完成项和剩余项。

### blocked

无法继续推进。必须写明：

- 阻塞原因。
- 需要谁决策。
- 当前已完成什么。
- 解除阻塞后从哪里继续。

### implemented

代码或文档已完成，但尚未完整验证。不能对外声称完成。

### verified

验收和验证已完成。必须记录：

- 验证命令。
- 验证结果。
- 未验证项和原因。
- 剩余风险。

### released

已进入发布、灰度或上线状态。必须记录：

- release 版本。
- 发布环境。
- 灰度比例。
- 回滚目标。
- smoke check 结果。

### archived

任务已归档。归档记录必须能让新会话理解任务背景、最终决策、变更文件和验证结果。

## 流转规则

- `idea` 只能流转到 `draft` 或废弃。
- `draft` 只能流转到 `ready` 或 `blocked`。
- `ready` 才能流转到 `in_progress`。
- `implemented` 必须经过验证才能到 `verified`。
- 没有发布影响的任务可以停在 `verified`。
- 有发布影响的任务必须继续到 `released` 或记录为什么暂不发布。
