---
name: new-feature
description: "当用户提出新功能开发需求时使用。"
disable-model-invocation: true
---

# /new-feature — 新功能全流程研发

> 触发完整五阶段流程：需求分析 → 产品设计 → 技术设计 → 代码实现(闭环) → 收尾

## 前置步骤

1. 读取 `workflows/full-lifecycle.md`，作为本次执行的完整流程参考
2. 读取 `CLAUDE.md` 中的强制规则 R1-R7
2.5. 读取 `workspace/memory.md` — 了解项目当前状态和已有决策
2.6. 读取 `docs/knowledges/` 下的已有知识文件（如存在）— 后续各阶段需参考
3. 向用户确认功能名称（用于创建 `docs/specs/{feature-name}/` 目录）
4. 创建 Task 链：
   ```
   Task 1: [P1] {feature} 需求分析
   Task 2: [P2] {feature} 产品设计        (blockedBy: Task 1)
   Task 3: [P3] {feature} 技术设计        (blockedBy: Task 2)
   Task 4: [P4] {feature} 代码实现        (blockedBy: Task 3)
   Task 5: [P5] {feature} 测试验证与收尾   (blockedBy: Task 4)
   ```
5. 初始化 `workspace/stage-status.json`（feature 字段填入功能名称）

---

## P1: 需求分析

0. 读取 docs/knowledges/domain/ 和 lessons-learned/（如存在）
1. 使用 AskUserQuestion 向用户澄清：
   - 核心目标是什么？
   - 目标用户是谁？
   - 必须有 vs 最好有 的功能边界？
2. 读取 `.claude/agents/pm-agent.md`，以 pm-agent 模式 A 的角色执行需求分析
3. 复制 `templates/requirement.md` 到 `docs/specs/{feature}/requirement.md`，填写所有章节
4. 确保每个用户故事有可测试的 AC，开放问题为空
5. 更新 `workspace/stage-status.json`：stage=requirement, status=running

### P1 门禁审查

按 `workflows/full-lifecycle.md` 中 P1 审查 prompt 执行：
- 启动 subagent（qa-agent 模式 D）检查：AC 可测试性、边缘情况
- 启动 subagent（arch-agent 模式 C）检查：数据域完整性、技术可行性
- CRITICAL 问题 → 修复后重审
- 无 CRITICAL → status 标记为 reviewed
- 更新 stage-status.json：status=waiting_approval
- **等待用户审批后继续**

---

## P2: 产品设计

1. 读取 `docs/specs/{feature}/requirement.md`
2. 以 pm-agent 模式 B 执行产品设计
3. 复制 `templates/product.md` 到 `docs/specs/{feature}/product.md`，填写所有章节
4. 更新 traces_to 双向链接

### P2 门禁审查

- 启动 subagent（arch-agent 模式 C）检查：信息架构、约束兼容性
- 启动 subagent（qa-agent 模式 D）检查：E2E 可测性、用户流程无死路
- CRITICAL 问题 → 修复后重审
- 无 CRITICAL → status=reviewed → waiting_approval
- **等待用户审批后继续**

---

## P3: 技术设计

0. 读取 docs/knowledges/architecture/, patterns/, standards/（如存在）
1. 读取 `docs/specs/{feature}/product.md` + `docs/architecture.md`
2. 以 arch-agent 模式 A 执行技术设计，同时以 qa-agent 模式 A 编写测试计划（可并行）
3. 产出：
   - `docs/specs/{feature}/tech.md`（使用 `templates/tech-design.md`）
   - `docs/specs/{feature}/test-plan.md`（使用 `templates/test-plan.md`）
   - `docs/plans/active/{feature}.md`（使用 `templates/exec-plan.md`）
4. 更新所有 traces_to 链接

### P3 门禁审查

- 启动 subagent（dev-agent）检查：API 可实现性、里程碑粒度
- 启动 subagent（qa-agent 模式 D）检查：测试覆盖、分层合规
- CRITICAL 问题 → 修复后重审
- 无 CRITICAL → 执行跨工件一致性检查（见 `workflows/full-lifecycle.md` §6.5）：
  - FR-### → tech.md → exec-plan 三角覆盖分析
  - 有 HIGH 级覆盖缺口 → 修复后重审
  - 术语漂移 → 记录为 MEDIUM 问题
  - 一致性检查通过 → status=waiting_approval
- **等待用户审批后继续**

---

## P4: 代码实现 — 触发 Close-Loop

用户审批 P3 后，执行 `/close-loop` 技能进入自动闭环。

---

## P5: 收尾 GC

Close-Loop 全部通过后：
1. 将 `docs/plans/active/{feature}.md` 移至 `docs/plans/completed/`
2. 更新 `docs/specs/index.md`：新增本功能索引行（名称、状态、描述、关键 API、页面、路径）
3. 更新 `docs/architecture.md`：如有新模块/API/数据表，追加到对应汇总表
4. 更新 `docs/quality.md`
5. 检查 traces_to 链接有效性
6. 知识沉淀到 `docs/knowledges/`（如有新发现）
7. 更新 stage-status.json：stage=gc, status=completed
6. 标记所有 Task 为 completed
7. 通知用户：功能完成，可进行人工验证
