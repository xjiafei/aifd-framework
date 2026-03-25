# AIFD 完整生命周期工作流

> 本文档是 CLAUDE.md 指向的单一详细参考文件，涵盖从需求到交付的全流程。

---

## 1. Triage 分流

收到任何请求后，首先根据下表判断应走哪条路径：

| 类型 | 识别特征 | 路径 | 说明 |
|------|----------|------|------|
| 新功能 | 用户明确提出新能力、新模块、新页面 | 完整五阶段 P1→P2→P3→P4→P5 | 需要完整的需求分析、产品设计、技术设计、实现和测试 |
| Bug修复 | 报告现有功能异常、错误、回归 | P3(技术设计)→P4(实现)→P5(测试) | 跳过需求和产品设计，直接定位问题并修复 |
| 重构 | 代码质量改进、架构调整、性能优化 | P3(技术设计)→P4(实现)→P5(测试) | 需要技术设计确保重构不破坏现有功能 |
| 配置/小改动 | 文案修改、配置变更、依赖升级等 | 直接实现→验证 | 风险极低，直接执行并验证即可 |
| **紧急热修（Hotfix）** | **生产环境严重故障、数据丢失风险、安全漏洞** | **简化P3→紧急P4→P5** | **跳过需求/产品设计，压缩技术设计，但必须保留Code Review和测试** |

**分流判断规则：**
- 如果涉及新的用户故事或业务流程 → 新功能
- 如果是已有功能不符合预期 → Bug修复
- 如果功能不变但内部结构调整 → 重构
- 如果改动少于 10 行且不涉及逻辑变更 → 配置/小改动
- 如果是生产故障且分钟级影响用户 → 紧急热修（Hotfix）

### 紧急热修（Hotfix）流程

> **使用前提**：必须是真实的生产紧急情况（P0 级别故障），不得滥用绕过正常流程。

**简化 P3**（最多 30 分钟）：
1. 快速根因分析（arch-agent 模式 A，只产出问题定位 + 修复方案，不写完整 tech.md）
2. 产出最小化 exec-plan（只有 1-3 个里程碑，每个不超过 30 分钟）
3. **风险声明**：必须明确声明绕过了哪些正常流程，以及已知风险

**紧急 P4**（保留核心门禁）：
1. dev-agent 实现修复（无正式 Code Review，但 reviewer-agent 做快速安全扫描）
2. qa-agent 只运行 P0 测试用例（跳过 P1/P2）
3. 人工确认修复结果

**P5（不可省略）**：
- 修复完成后 24 小时内补写完整的事后分析文档（`docs/knowledges/lessons-learned/hotfix-xxx.md`）
- 补充回归测试用例防止复现
- 审查是否需要通过正常流程补写 requirement.md / tech.md

---

## 2. 流程总览图

```
                         AIFD 完整生命周期流程
                         =====================

  ┌─────────┐
  │ Triage  │ ── 配置/小改动 ──→ 直接实现 → 验证 → 完成
  │  分流   │ ── Bug/重构 ────→ P3 开始
  └────┬────┘
       │ 新功能
       ▼
  ┌─────────┐     ┌──────┐     ┌─────────┐     ┌──────┐     ┌─────────┐
  │   P1    │────→│ Gate │────→│   P2    │────→│ Gate │────→│   P3    │
  │ 需求分析 │     │ 评审  │     │ 产品设计 │     │ 评审  │     │ 技术设计 │
  └─────────┘     └──────┘     └─────────┘     └──────┘     └────┬────┘
                                                                  │
                                                             ┌──────┐
                                                             │ Gate │
                                                             │ 评审  │
                                                             └──┬───┘
                                                                │
       ┌────────────────────────────────────────────────────────┘
       ▼
  ┌──────────────────────────────────────────────────────┐
  │              P4: 实现 — Close-Loop 自动闭环           │
  │                                                      │
  │  ┌────────┐   ┌──────────┐   ┌──────┐   ┌───────┐  │
  │  │ Coding │→ │Code Review│→ │Testing│→ │Accept │  │
  │  │  编码   │   │  代码评审  │   │ 测试  │   │ 验收  │  │
  │  └────────┘   └──────────┘   └──────┘   └───────┘  │
  │       ▲                                      │       │
  │       └──────── 失败则修复重来 (最多3轮) ──────┘       │
  └──────────────────────┬───────────────────────────────┘
                         │ 全部通过
                         ▼
                    ┌─────────┐
                    │   P5    │
                    │ 收尾 GC  │
                    └─────────┘
```

---

## 3. Task Tracking 集成

启动完整生命周期时，创建 Task 链：

```
Task 1: [P1] 需求分析        (blockedBy: none)
Task 2: [P2] 产品设计        (blockedBy: 1)
Task 3: [P3] 技术设计        (blockedBy: 2)
Task 4: [P4] 代码实现        (blockedBy: 3)
Task 5: [P5] 测试验证与收尾   (blockedBy: 4)
```

**Task 状态流转：**
- `pending` → 等待上游完成
- `in_progress` → 当前阶段执行中
- `waiting_approval` → Gate 评审通过，等待人工审批
- `completed` → 阶段完成，下游可开始
- `failed` → 阶段失败，需人工介入

每个 Task 完成时更新 `workspace/stage-status.json`（见第 10 节）。

---

## 3.5 子代理调度规则

### 上下文隔离原则

子代理只传入任务相关的文件内容，不继承会话历史。
**"更少的上下文 = 更可靠的执行"**

### 调度时传入

| 传入内容 | 示例 |
|---------|------|
| 角色 agent 文件内容 | .claude/agents/pm-agent.md 的完整内容 |
| 当前阶段输入文件 | docs/specs/{feature}/requirement.md |
| 相关编码标准 | docs/knowledges/standards/{tech}.md |
| 当前里程碑/任务描述 | exec-plan 中的具体里程碑 |

### DYNAMIC_INJECT 填充协议（编排者必须执行）

**核心机制**：agent 文件中的 `<!-- DYNAMIC_INJECT_START/END -->` 是注入点标记，表示"派发此 agent 时，在此处追加项目上下文"。**不需要修改 agent 文件本身**，而是在调用 Agent 工具时，将注入内容拼入 prompt。

**三步操作**：

**Step 1 — 读取 agent 文件**
```
Read .claude/agents/xxx-agent.md → 获取 agent 完整指令
```

**Step 2 — 收集注入内容**（从以下来源读取）

| 注入字段 | 来源 |
|---------|------|
| 项目名称、技术栈、构建命令、测试命令 | `CLAUDE.md §8 项目定制区` |
| 当前功能名称 | `workspace/stage-status.json` → `features` 中 running 的功能 |
| 相关知识文件路径 | `docs/knowledges/index.md` → 按业务关键词匹配 |
| 代码规范（dev-agent 额外） | `docs/knowledges/standards/{tech}.md`（如存在） |
| 当前里程碑（dev-agent 额外） | `docs/plans/active/{feature}.md` 当前里程碑 |

**Step 3 — 拼接 prompt 后调用 Agent 工具**

```
[agent 文件完整内容]

---
## 当前项目上下文（编排者注入）

- **项目名称**：{xxx}
- **技术栈**：{xxx}
- **构建命令**：{xxx}
- **测试命令**：{xxx}
- **当前功能**：{feature-name}
- **相关知识**：[docs/knowledges/xxx.md, ...]
（dev-agent 额外）
- **代码规范**：docs/knowledges/standards/{tech}.md
- **当前里程碑**：M### — {里程碑描述}
---

[具体任务描述]
```

> **如果 CLAUDE.md §8 为空**（未完成 `/init-project`），只注入功能名称和知识文件路径，其余字段省略。

### 调度时不传入

| 不传入内容 | 原因 |
|-----------|------|
| 之前阶段的对话历史 | 无关信息干扰判断 |
| 其他角色的 agent 文件 | 角色混淆 |
| 不相关模块的代码 | 上下文噪声 |
| workspace/ 日志文件 | 非任务必要 |

### 子代理返回规范

子代理完成后应返回**结构化摘要**，包含：
- 产出文件路径
- 关键决策说明
- 发现的问题（如有）
- 建议的下一步

不要返回原始输出全量——编排者只需知道结果，不需要过程细节。

---

## 4. P1: 需求分析

### 4.0 上下文加载（强制）

**必须执行，不可跳过**：

1. 读取 `docs/knowledges/index.md`，按业务领域关键词匹配相关条目
2. 对匹配的条目，读取文件内容（重点：domain/ 和 lessons-learned/）
3. 读取 `workspace/memory.md` — 了解项目当前状态和已有决策
4. **教训应用检查**：如匹配到的 lessons-learned 条目含"模板改进建议"或"规则改进建议"字样，先检查 `docs/templates/` 或 `.claude/rules/` 是否已响应更新。**未更新则在继续流程之前完成更新**，确保教训在本轮生效。
5. 在后续输出中注明参考了哪些知识条目（增加可追溯性）

> 若 docs/knowledges/index.md 不存在，说明项目初始化未完成，执行 `/init-project` 后再继续。

### 4.1 读取用户需求输入

读取用户提供的需求描述，初步理解业务背景和期望目标。

### 4.2 澄清歧义

使用 `AskUserQuestion` 与用户交互，至少确认以下三点：
- **核心目标**：这个功能要解决什么问题？成功的衡量标准是什么？
- **目标用户**：谁会使用这个功能？使用场景是什么？
- **边界划定**：哪些是必须有的（must-have）？哪些是锦上添花的（nice-to-have）？

### 4.3 派发 PM Agent

读取 `.claude/agents/pm-agent.md`，以 **模式 A** 派发为子代理。

PM Agent 执行需求分析，产出结构化需求文档。

### 4.4 输出物

- 文件路径：`docs/specs/{feature-name}/requirement.md`
- 使用模板：`docs/templates/requirement.md`
- 内容须包含：用户故事、验收标准(AC)、数据域定义、非功能性需求、traces_to 链接

### 4.5 Gate 评审

**第一步：自动预检（precheck-agent）**

派发 `precheck-agent` 对需求文档进行结构性预检：
```
doc_path: docs/specs/{feature-name}/requirement.md
doc_type: requirement
feature_name: {feature-name}
```
- 预检 **FAIL**（存在 CRITICAL 问题）→ 修复后重新预检
- 预检 **PASS** 或 **WARN** → 进入人工评审

**第二步：领域评审**

派发评审团队为子代理：

| 评审角色 | Agent | 模式 | 评审重点 |
|----------|-------|------|----------|
| QA评审 | qa-agent | 模式 D | AC 可测试性、边缘情况覆盖 |
| 架构评审 | arch-agent | 模式 C | 数据域完整性、技术可行性 |

**评审 Prompt 模板：**

```
审查 docs/specs/{name}/requirement.md:

审查维度（需求的单元测试 — 借鉴 SpecKit "unit tests for English" 理念）：

□ 完整性 — 是否覆盖了所有用户角色和场景？有没有遗漏的用户故事？
□ 清晰性 — 是否有歧义表达？每句话是否只有一种理解方式？
□ 一致性 — 需求之间是否有矛盾？术语是否统一？
□ 可测量性 — 每个 AC 是否可以转化为自动化测试断言？（不可测量 = 不通过）
□ 边缘覆盖 — 空输入/并发/权限不足/网络异常/数据边界是否考虑？
□ 依赖识别 — 是否有未声明的外部系统/服务/数据依赖？
□ 术语统一 — 同一概念是否在文档中只用一个名称？

1. 每个用户故事是否有可测试的 AC?
   ❌ 不通过示例: "系统应该快" (不可测试)
   ✅ 通过示例: "API P95 响应时间 < 200ms"

2. 是否有未回答的开放问题?

3. 边缘情况: 空输入/并发/权限不足/网络异常是否考虑?

4. 数据域: 业务对象的类型/长度/约束/默认值是否定义?

5. traces_to 字段是否已填写?

输出: PASS 或 FAIL + [具体问题列表]
```

**评审结果处理：**
- 存在 **CRITICAL** 问题 → 修复后重新评审
- 无 CRITICAL 问题 → 标记 `status: reviewed` → 更新 `stage-status.json` → **等待人工审批**

---

## 5. P2: 产品设计

### 5.1 输入物

- `docs/specs/{feature-name}/requirement.md`（已通过 P1 Gate）

### 5.2 派发 PM Agent

读取 `.claude/agents/pm-agent.md`，以 **模式 B** 派发为子代理。

PM Agent 基于需求文档进行产品设计，包括信息架构、用户流程、交互规范。

### 5.3 输出物

- 文件路径：`docs/specs/{feature-name}/product.md`
- 内容须包含：信息架构、用户流程图、页面/接口交互说明、状态流转、错误处理策略

### 5.4 Gate 评审

**第一步：自动预检（precheck-agent）**

```
doc_path: docs/specs/{feature-name}/product.md
doc_type: product
feature_name: {feature-name}
```
预检 FAIL → 修复后重新预检。PASS/WARN → 进入领域评审。

**第二步：领域评审**

派发评审团队为子代理：

| 评审角色 | Agent | 模式 | 评审重点 |
|----------|-------|------|----------|
| 架构评审 | arch-agent | 模式 C | 信息架构完整性、技术约束对齐 |
| QA评审 | qa-agent | 模式 D | 端到端可测试性、用户流程无死胡同 |

**评审重点：**
1. 信息架构是否完整？所有实体和关系是否明确？
2. 用户流程是否端到端可测试？每条路径是否有明确的入口和出口？
3. 用户流程是否存在死胡同（用户无法继续或返回的状态）？
4. 错误状态和空状态是否有设计？
5. 与 requirement.md 中的 AC 是否完全对应？

**评审结果处理：**
- 存在 **CRITICAL** 问题 → 修复后重新评审
- 无 CRITICAL 问题 → 标记 `status: reviewed` → 更新 `stage-status.json` → **等待人工审批**

---

## 6. P3: 技术设计

### 6.0 上下文加载（强制）

**必须执行，不可跳过**：

1. 读取 `docs/knowledges/index.md`，按技术栈和功能类型匹配相关条目
2. 对匹配的条目，优先读取：
   - `architecture/` — 已有 ADR，避免重复讨论已决事项
   - `patterns/` — 已沉淀的代码模式，优先复用
   - `standards/` — 编码规范，技术设计须符合
3. 在 tech.md 的"参考知识"章节注明引用了哪些知识条目

> 首次使用时 knowledges/ 可能为空，正常继续。后续功能会逐步填充。

### 6.1 顺序派发

顺序派发两个子代理（qa-agent 依赖 arch-agent 的 tech.md 输出）：

**第一步**：派发 arch-agent（模式 A）
- 输入：`product.md` + `architecture.md`
- 输出：`tech.md` + `exec-plan`

**第二步**：派发 qa-agent（模式 A）（在 arch-agent 完成后）
- 输入：`tech.md` + `requirement.md`
- 输出：`test-plan.md` + `test-cases.md`

### 6.2 arch-agent 输出物

- `docs/specs/{feature-name}/tech.md` — 技术设计文档
  - 包含：模块划分、API 设计、数据模型、依赖关系、层级约束
- `docs/plans/active/{feature}.md` — 执行计划
  - 包含：里程碑拆分、每个里程碑的具体任务、构建命令、预期输出

### 6.3 qa-agent 输出物

- `docs/specs/{feature-name}/test-plan.md` — 测试计划
  - 包含：测试策略、测试范围、测试环境要求
- `docs/specs/{feature-name}/test-cases.md` — 测试用例
  - 包含：每条用例的前置条件、操作步骤、预期结果、优先级(P0/P1/P2)

### 6.4 Gate 评审

**第一步：自动预检（precheck-agent，并行运行三个文档）**

```
文档1: doc_path=docs/specs/{feature-name}/tech.md,       doc_type=tech
文档2: doc_path=docs/plans/active/{feature-name}.md,     doc_type=exec-plan
文档3: doc_path=docs/specs/{feature-name}/test-plan.md,  doc_type=test-plan
```
任一文档预检 FAIL（CRITICAL 问题）→ 修复后重新预检该文档。全部 PASS/WARN → 进入领域评审。

**第二步：领域评审**

派发评审团队为子代理：

| 评审角色 | Agent | 模式 | 评审重点 |
|----------|-------|------|----------|
| 开发评审 | dev-agent | — | API 可实现性、里程碑粒度 |
| QA评审 | qa-agent | 模式 D | 测试用例覆盖率、与 AC 的对应关系 |

**评审重点：**
1. 层级合规性 — 是否遵循 `architecture.md` 中的分层约束？
2. 依赖方向 — 是否存在反向依赖或循环依赖？
3. API 可实现性 — 接口定义是否足够清晰，开发可直接编码？
4. 里程碑粒度 — 每个里程碑是否足够小（可在单次迭代中完成）？
5. 构建命令 — 是否明确指定了构建和验证命令？

**评审结果处理：**
- 存在 **CRITICAL** 问题 → 修复后重新评审
- 无 CRITICAL 问题 → 进入跨工件一致性检查

### 6.5 跨工件一致性检查（P3 Gate 通过后、等待审批前）

> 自动执行只读分析，检查三份文档之间的覆盖缺口和术语漂移。

**三角检查：FR-### → tech.md → exec-plan 里程碑**

```
检查矩阵：
| FR-### | 对应 tech.md 章节 | 对应 exec-plan 里程碑 | 状态 |
|--------|-----------------|---------------------|------|
| FR-001 | §3.API 设计       | M002                | ✅   |
| FR-002 | 未提及            | —                   | ❌ 覆盖缺口 |
| FR-003 | §4.数据模型        | M003                | ✅   |
```

**覆盖缺口处理规则：**
- 某 FR-### 在 tech.md 中无对应设计 → **HIGH**，必须修复才能 `waiting_approval`
- 某 FR-### 有 tech 设计但无对应里程碑 → **HIGH**，必须修复
- 某里程碑无对应 FR-### 来源 → **MEDIUM**，记录并说明必要性

**术语漂移检测：**
- 同一概念在 `requirement.md` / `tech.md` / `exec-plan` 中名称不一致 → **MEDIUM**
- 修复方式：统一使用 requirement.md 中定义的术语

**一致性检查通过标准：**
- 无 HIGH 级覆盖缺口
- MEDIUM 问题已记录说明（不强制修复）

通过后 → 更新 `stage-status.json: status=waiting_approval` → **等待人工审批**

---

## 7. P4: 实现 — Close-Loop 自动闭环

```
最多 3 轮。每轮结果持久化到 workspace/。
```

### 7.0 上下文加载（强制）

**必须执行，不可跳过**：

1. 读取 `docs/knowledges/index.md`，按技术栈和模块名匹配相关条目
2. 重点读取：
   - `standards/` — 编码规范，代码必须符合（如不存在则遵循 `.claude/rules/general.md`）
   - `patterns/` — 已沉淀模式，优先复用，不重新发明
3. 在 dev-agent 的实现说明中注明"复用了模式 {X}"或"首次实现此模式"

### 7.1 Coding（dev-agent 编码）

1. 读取 `exec-plan`，按里程碑逐个实现
2. 每个里程碑执行流程：
   - 编写代码
   - 运行构建命令
   - 验证构建结果
3. **构建通过** → 更新 `exec-plan` 中该里程碑状态为 `"done"`
4. **构建失败** → 修复 → 重试（每个里程碑最多重试 3 次）
5. 单个里程碑 3 次重试仍失败 → 记录错误，继续下一个里程碑，最终汇总报告

### 7.2 Code Review（reviewer-agent 代码评审）

1. 审查范围：Round 1 审查所有变更文件；Round N>1 审查本轮新增/修改文件（增量审查）
2. 参考 `docs/knowledges/standards/` 中的编码规范作为评审标准
3. 输出问题列表，按严重程度分级：

| 级别 | 含义 | 处理方式 |
|------|------|----------|
| CRITICAL | 安全漏洞、数据丢失风险、架构违规 | 必须修复，派发 dev-agent 修复后重新评审；内部重试上限 3 次，超出则 +1 轮次重启 |
| HIGH | 明显 Bug、性能问题、缺失错误处理 | **必须明确决策**：立即修复 或 登记 tracked debt（含处理计划），不可静默继续 |
| MEDIUM | 代码风格、可读性、最佳实践偏离 | 建议修复，记录到 `docs/specs/{feature}/review-log.md` |
| LOW | 命名建议、注释补充 | 可选修复，记录到 `docs/specs/{feature}/review-log.md` |

4. 所有问题记录到 `docs/specs/{feature}/review-log.md`（OPEN 状态）
5. 结论档位（见 reviewer-agent.md）：
   - `APPROVED`：无 CRITICAL 且无 HIGH → 可进入 4.3
   - `APPROVED_WITH_HIGH`：无 CRITICAL，有 HIGH → 必须完成 HIGH 决策后才可进入 4.3
   - `BLOCKED`：有 CRITICAL → 修复后重新执行 7.2

### 7.3 Testing（qa-agent 模式 B 测试执行）

1. 逐条执行 `test-cases.md` 中的 **所有** 测试用例（P0 不可跳过）
2. 输出覆盖率矩阵（每条用例必须有执行状态）：

```
| 用例ID | 描述 | 优先级 | 状态 | 备注 |
|--------|------|--------|------|------|
| TC-001 | ...  | P0     | PASS | —    |
| TC-002 | ...  | P0     | FAIL | 错误信息 |
| TC-003 | ...  | P0     | BLOCKED | 阻塞原因 |
```

3. **测试覆盖完整性门禁（必须通过才能继续）**：
   - 覆盖矩阵无 `not-executed` / `pending` 的 P0 用例
   - 所有 P0 用例为 PASS（BLOCKED 需说明原因，不可静默跳过）
4. **结构化输出（必须持久化，与功能文档一起归档）**：
   - 将覆盖率矩阵写入 `docs/specs/{feature}/test-report.md`（每轮追加，标注 Round N）
   - 将测试结论写入 `docs/specs/{feature}/test-result.json`，格式：
     ```json
     {
       "feature": "{feature-name}",
       "round": 1,
       "updatedAt": "ISO timestamp",
       "summary": { "total": 0, "pass": 0, "fail": 0, "blocked": 0 },
       "verdict": "PASS | FAIL",
       "p0Bugs": [],
       "p1p2Bugs": []
     }
     ```
5. **P0 Bug 存在** → 触发 BUG_FIX Restart，+1 轮次
6. **P1/P2 Bug** → 记录到 `docs/specs/{feature}/review-log.md`（与 CR 日志共用，标注来源为 testing），继续流程

### 7.4 Acceptance（验收）

同时进行技术验收和功能验收：

| 验收类型 | Agent | 模式 | 验收内容 |
|----------|-------|------|----------|
| 技术验收 | arch-agent | 模式 B | 实现是否符合技术设计？架构约束是否遵守？ |
| 功能验收 | pm-agent | 模式 C | 所有 AC 是否满足？功能是否符合产品设计？ |

**验收失败时，验收 agent 必须输出失败分类（三选一）**：

| 类型 | 含义 | 处理方式 |
|------|------|----------|
| **类型A：实现 Bug** | 代码与设计一致，但实现有错误 | dev-agent 修复 → 从 4.2 Code Review 继续（不 +1 轮次） |
| **类型B：设计缺口** | tech.md 设计不足以实现 AC | arch-agent 更新 tech.md + exec-plan → 从 4.1 Coding 继续（+1 轮次） |
| **类型C：需求分歧** | AC 与用户真实意图不符 | 立即暂停，AskUserQuestion 人工澄清（不消耗轮次），可能需回退到 P2/P3 |

- **验收通过** → 进入退出条件检查

### 7.5 退出条件

**以下全部满足方可退出 P4：**

- ✅ 构建成功（0 错误）
- ✅ Code Review：无 CRITICAL，HIGH 问题已明确处理（立即修复 或 登记 tracked debt）
- ✅ 测试覆盖矩阵完整，P0 用例全部 PASS（无未执行的 P0 用例）
- ✅ 技术验收通过（arch-agent 模式B 结论 PASS）
- ✅ 功能验收通过（pm-agent 模式C 结论 PASS）

**3 轮后仍未满足退出条件：**
1. **暂停流程**
2. 更新 `stage-status.json`，记录所有未解决的错误
3. 使用 `AskUserQuestion` 请求人工介入
4. 人工介入后根据指示继续或终止

---

## 8. P5: 收尾 GC

### 8.1 归档执行计划

将 `docs/plans/active/{feature}.md` 移动到 `docs/plans/completed/{feature}.md`。

### 8.2 更新质量文档

更新 `docs/quality.md`，补充本次实现中发现的新洞察：
- 新的质量基线数据
- 发现的典型问题模式
- 改进的验证方法

### 8.3 检查 traces_to 链接有效性

遍历本次产出的所有文档，验证每个 `traces_to` 链接指向的文件是否存在。
- 链接失效 → 修复或移除
- 链接缺失 → 补充

### 8.4 更新全局索引

- 更新 `docs/specs/index.md`：新增本功能的索引行（功能名、状态、一行描述、关键 API、关键页面、路径）
- 更新 `docs/architecture.md`：如有新增模块/API/数据表，追加到对应汇总表（模块表、API 汇总表、数据模型概览）

> 注意：只登记摘要信息和链接，不复制详细内容。详细内容在 feature 目录中维护。

### 8.5 知识沉淀

| 沉淀类型 | 目标路径 | 内容 |
|----------|----------|------|
| 新模式 | `knowledges/patterns/` | 本次实现中值得复用的设计模式、代码模式 |
| 经验教训 | `knowledges/lessons-learned/` | 踩过的坑、绕过的弯路、时间浪费点 |

**沉淀后强制执行 — 教训闭环（不可跳过）**：

沉淀完成后，如本次 lessons-learned 包含模板改进或规则改进建议，必须在**同一 P5 步骤内**完成以下操作：

1. 在 `docs/templates/` 或 `.claude/rules/` 中完成对应更新（不可延迟到"下次"）
2. 在 lessons-learned 文件末尾追加 `applied_to` 字段，例如：
   ```
   applied_to: docs/templates/requirement.md（已更新 FR-### 编号规范）
   ```
3. 若暂时无法确定改进方案，标记 `applied_to: PENDING — 原因：{说明}`，但不可省略此字段

> **为什么**：lesson 被写入但未应用 = 无效沉淀。只有在下一轮功能开始前确认已更新模板/规则，自进化才能真正生效。

### 8.6 框架自检（每 3 个功能执行一次）

每完成 3 个功能后，执行框架健康检查：

1. **CLAUDE.md 导航有效性** — 所有链接是否指向存在的文件？
2. **模板改进需求** — `docs/templates/` 中的模板是否需要根据实践经验更新？
3. **新文件注册** — 本次新增的重要文件是否已在 CLAUDE.md 中注册？

自检结果记录到 `workspace/framework-health.md`。发现问题直接修复（更新 CLAUDE.md / templates 等）。

---

## 9. 回退协议

当任何阶段发现上游产物存在问题时，执行以下协议：

```
步骤 1: 在当前阶段的产物中添加反馈记录

  ## Feedback Log
  - [{date}] 来自 {当前阶段}: {问题描述}

步骤 2: 在上游产物中添加反馈记录

  ## Feedback Log
  - [{date}] 来自 {下游阶段} 的反馈: {问题描述}

步骤 3: 重置上游产物状态为 "draft"

步骤 4: 派发对应角色 Agent 修复上游产物

步骤 5: 重新执行该阶段的 Gate 评审

步骤 6: 评审通过 → 继续下游流程
```

**回退示例：**
- P3 技术设计发现 P2 产品设计缺少某个用户流程
  1. 在 `tech.md` 添加 Feedback Log
  2. 在 `product.md` 添加 Feedback Log
  3. 重置 `product.md` 状态为 `draft`
  4. 派发 pm-agent(模式 B) 补充缺失的用户流程
  5. 重新执行 P2 Gate 评审
  6. 评审通过后继续 P3

**注意事项：**
- 回退仅回退一级（P3 只能回退到 P2，不能跳级回退到 P1）
- 如需跨级回退，需逐级执行
- 每次回退都必须更新 `stage-status.json`

---

## 10. workspace/stage-status.json 更新规则

### 更新时机

| 事件 | 更新内容 |
|------|----------|
| 新功能启动 | 在 `features` 下新增 `{feature-name}` 键 |
| 阶段转换 | 更新对应功能的 `stage`, `subStage`, `status`, `agent`, `summary` |
| Gate 评审结果 | 更新功能的 `status` 为 `waiting_approval` 或 `running` |
| 人工审批通过 | 更新功能的 `status` 为 `running`，推进到下一阶段 |
| 发生错误 | 追加到功能的 `errors` 数组 |
| Close-Loop 轮次变更 | 更新功能的 `loopRound` |
| 功能完成 | 更新功能的 `status` 为 `completed` |

### 文件格式（v2 多功能格式）

```json
{
  "features": {
    "{feature-name}": {
      "stage": "requirement|product|tech|implementation|gc",
      "subStage": "coding|code-review|testing|acceptance",
      "status": "running|completed|waiting_approval|failed",
      "loopRound": 1,
      "updatedAt": "ISO timestamp",
      "startedAt": "ISO timestamp",
      "completedAt": "ISO timestamp",
      "agent": "current agent",
      "summary": "one-line description",
      "outputs": ["file paths"],
      "errors": [],
      "metrics": {
        "gateFailCount": 0,
        "loopRoundTotal": 0,
        "crCriticalCount": 0,
        "crHighCount": 0
      }
    }
  },
  "projectName": "{project-name}",
  "lastUpdated": "ISO timestamp",
  "_schema": "v2-multi-feature",
  "archived": []
}
```

### 字段说明（features.{name} 内字段）

| 字段 | 类型 | 说明 |
|------|------|------|
| `stage` | enum | 当前所处的大阶段 |
| `subStage` | string | P4 闭环中的子阶段，其他阶段可为空 |
| `status` | enum | `running`=进行中, `waiting_approval`=等待人工审批, `completed`=完成, `failed`=失败需人工介入 |
| `loopRound` | number | P4 闭环的当前轮次（1-3） |
| `startedAt` | string | 功能开始时间（P1 启动时记录） |
| `completedAt` | string | 功能完成时间（P5 GC 完成时记录） |
| `updatedAt` | string | ISO 8601 格式的最后更新时间戳 |
| `agent` | string | 当前负责的 Agent 名称 |
| `summary` | string | 当前状态的一句话描述 |
| `outputs` | array | 本阶段已产出的文件路径列表 |
| `errors` | array | 累积的错误信息列表 |
| `metrics.gateFailCount` | number | Gate 评审失败次数（CRITICAL 问题被打回次数） |
| `metrics.loopRoundTotal` | number | P4 最终使用的总循环轮次 |
| `metrics.crCriticalCount` | number | Code Review 发现的 CRITICAL 问题总数 |
| `metrics.crHighCount` | number | Code Review 发现的 HIGH 问题总数 |

### archived 字段说明

`archived` 数组存放已完成超过 30 天的功能摘要（从 features 中移出，防止无限膨胀）：

```json
"archived": [
  {
    "name": "feature-name",
    "completedAt": "ISO timestamp",
    "loopRoundTotal": 2,
    "crCriticalCount": 0,
    "specsPath": "docs/specs/feature-name/"
  }
]
```

**归档触发规则**：每次 health-check 时，将 `status=completed` 且 `completedAt` 超过 30 天的功能从 `features` 移入 `archived`。

### 状态流转示例（多功能并行）

```
功能 A P1 开始:
  features["feature-a"] = { stage: "requirement", status: "running", agent: "pm-agent" }

功能 A P1 Gate 通过（同时功能 B 也可以启动）:
  features["feature-a"] = { stage: "requirement", status: "waiting_approval" }
  features["feature-b"] = { stage: "requirement", status: "running", agent: "pm-agent" }

功能 A 进入 P4（只有 feature-a 的 stage=implementation+status=running 时，才允许编写功能 A 的代码）:
  features["feature-a"] = { stage: "implementation", subStage: "coding", loopRound: 1 }

功能 A P5 完成:
  features["feature-a"] = { stage: "gc", status: "completed" }
```

### Hook 守卫逻辑

`.claude/hooks/check-coding-gate.sh` 的检查逻辑：
- 在 `features` 中找到任意一个 `stage=="implementation" && status=="running"` 的功能
- 如果找到 → 允许编写代码（允许所有活跃功能的代码路径）
- 如果找不到 → 阻止，提示需要先完成 P1-P3 并进入 /close-loop
