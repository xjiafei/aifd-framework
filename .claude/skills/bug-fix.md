---
name: bug-fix
description: "当用户报告 Bug、异常或需要修复缺陷时使用。"
disable-model-invocation: true
---

# /bug-fix — 缺陷修复流程

> 简化流程：技术设计 → 代码实现(闭环) → 收尾。跳过需求分析和产品设计。

## 前置步骤

1. 读取 `workflows/full-lifecycle.md`，定位到 P3-P5 相关章节
2. 读取 `CLAUDE.md` 中的强制规则
3. 向用户确认：
   - Bug 描述和复现步骤
   - 影响范围（哪些模块/仓库）
   - 紧急程度
4. 创建 Task 链：
   ```
   Task 1: [P3] {bug-id} 技术分析与修复方案
   Task 2: [P4] {bug-id} 修复实现        (blockedBy: Task 1)
   Task 3: [P5] {bug-id} 验证与收尾      (blockedBy: Task 2)
   ```
5. 初始化 `workspace/stage-status.json`

---

## P3: 技术分析与修复方案

0. 读取 docs/knowledges/lessons-learned/（如存在）— 检查是否有类似问题的历史修复经验
1. 以 arch-agent 模式 A 分析 Bug 根因
2. 产出简化版技术设计：
   - `docs/plans/active/{bug-id}.md`（使用 `docs/templates/exec-plan.md`）
   - 包含：根因分析、修复方案、受影响文件、验证命令
3. 不需要完整的 tech.md，exec-plan 中写清修复方案即可

### P3 门禁

- 启动 subagent 快速审查：修复方案是否合理、是否会引入新问题
- 更新 stage-status.json → waiting_approval
- **等待用户确认修复方案**

---

## P4: 修复实现 — 触发 Close-Loop

用户确认方案后，执行 `/close-loop` 技能进入自动闭环。

---

## P5: 收尾

1. exec-plan 移至 `docs/plans/completed/`
2. 更新 `workspace/stage-status.json`：status=completed
3. **强制：追加回归测试用例**
   - 在 `docs/specs/{feature}/test-cases.md` 中（若存在）或 `docs/specs/{bug-id}/test-cases.md` 中追加：
     ```
     ### TC-REG-{###} 回归用例：{bug标题}
     - **前置条件**：复现 Bug 所需的初始状态
     - **执行步骤**：与 Bug 报告中的复现步骤一致
     - **预期结果**：修复后的正确行为（不是 Bug 表现）
     - **优先级**：P0（防止复现）
     ```
   - 此用例在 close-loop 中由 qa-agent 自动覆盖，确保每次回归都执行
4. 如根因涉及架构问题，记录到 `docs/knowledges/lessons-learned/{bug-id}.md`
5. 检查同类 Bug：是否有其他模块可能存在相同问题？如有，在 code-review-log.md 记录为 OPEN 项
6. 通知用户：Bug 已修复，回归用例已追加
