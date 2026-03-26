---
name: new-feature
description: "当用户明确要求启动新功能的完整研发流程（需求分析→产品设计→技术设计→实现→收尾）时使用。触发词：/new-feature、新增功能、开发新功能、启动功能研发。"
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
3. 复制 `docs/templates/requirement.md` 到 `docs/specs/{feature}/requirement.md`，填写所有章节
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
3. 复制 `docs/templates/product.md` 到 `docs/specs/{feature}/product.md`，填写所有章节
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
   - qa-agent 模式 A 须同时规划 E2E 测试：
     a. 识别 product.md 中的关键用户流程 → 为每个关键流程创建至少一个 E2E 用例
     b. 在 test-cases.md 的 E2E 区域编写结构化用例（start_url、e2e_steps、expected_dom_state）
     c. 标注每个 E2E 用例的执行策略（Prong A / Prong B）
     d. 在 test-plan.md 填写 E2E 测试环境配置表（启动命令、健康检查 URL）
3. 产出：
   - `docs/specs/{feature}/tech.md`（使用 `docs/templates/tech-design.md`）
   - `docs/specs/{feature}/test-plan.md`（使用 `docs/templates/test-plan.md`）
   - `docs/plans/active/{feature}.md`（使用 `docs/templates/exec-plan.md`）
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

用户审批 P3 后，进入编码前的分支准备：

### 分支准备（仅当 CLAUDE.md §8 代码仓库路径表非空时执行）

1. 读取 CLAUDE.md §8 代码仓库路径表，获取所有仓库及其主分支
2. 读取 `docs/plans/active/{feature}.md`，分析各里程碑涉及修改的代码目录
3. 将涉及修改的目录映射到对应仓库（按路径前缀匹配）
4. 对每个需要修改的仓库：
   a. `cd {repo-path}`
   b. `git checkout {default-branch} && git pull`（确保基于最新代码）
   c. `git checkout -b feature/{feature-name}`
   d. 确认分支创建成功
5. 更新 `workspace/stage-status.json` 中本 feature 的 `repos` 数组：
   ```json
   "repos": [
     { "name": "{repo}", "path": "{path}", "defaultBranch": "{branch}", "featureBranch": "feature/{feature-name}", "branchCreated": true, "branchMerged": false }
   ]
   ```
6. 不涉及修改的仓库：不创建分支，不记录到 repos 数组

> 如果 CLAUDE.md §8 代码仓库路径表为空，跳过分支准备，直接进入 /close-loop。

然后执行 `/close-loop` 技能进入自动闭环。

---

## P5: 收尾 GC

Close-Loop 全部通过后：

1. **整理执行计划**：标记所有里程碑 `[x]`，填写 Progress Log（实际完成日期+备注），设 `status: completed`
2. 将 `docs/plans/active/{feature}.md` 移至 `docs/plans/completed/`
3. 更新 `docs/specs/index.md`：新增本功能索引行（名称、状态、描述、关键 API、页面、路径）
4. 更新 `docs/architecture.md`：如有新模块/API/数据表，追加到对应汇总表
5. 更新 `docs/quality.md`
6. **更新 `workspace/cr-index.md`**：添加本功能行，填入 review-log.md 最终 OPEN 计数
7. **登记遗留问题**：扫描 review-log.md 中所有 OPEN 条目（MEDIUM/LOW），在 `workspace/memory.md` 区域 C 记录为活跃约束
8. **刷新 `workspace/stage-status.json`**：校正 metrics、设 completedAt、修正 outputs 路径、设 stage=gc + status=completed
8.5. **分支合并提醒**（仅当 stage-status.json 中本 feature 有 `repos` 数组时）：
   - 扫描 repos 数组中 `branchCreated == true && branchMerged == false` 的仓库
   - 输出合并提醒：仓库名、特性分支、目标主分支、合并命令参考
   - 使用 AskUserQuestion 询问用户是否已完成合并
   - 已合并 → 更新 repos[].branchMerged = true
   - 暂不合并 → 在 workspace/memory.md 区域 C 记录待合并分支
9. 检查 traces_to 链接有效性
10. 知识沉淀到 `docs/knowledges/`（如有新发现）
11. **BLOCKED 用例确认**：如有 BLOCKED 测试用例，验证已登记到 memory.md 区域 C（含解封条件），通知用户待手动验收清单
12. 运行 post-stage-check：`bash .claude/hooks/post-stage-check.sh gc {feature}`
13. 标记所有 Task 为 completed
14. 通知用户：功能完成，列出待手动验证项（如有）
