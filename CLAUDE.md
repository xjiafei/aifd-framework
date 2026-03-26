# AIFD Framework 执行协议

> 本文件是可执行协议，不是文档。所有指令以"当…则…"格式编写。

---

## 1. 触发规则 — 请求自动分类与路由

当用户请求到达时，按关键词自动分类并路由到对应流程：

| 分类 | 触发词 | 执行流程 |
|------|--------|----------|
| 新功能 | 新增、添加、实现、开发 | 完整五阶段：需求 → 架构 → 实现 → 测试 → 交付 |
| 缺陷修复 | 修复、Bug、错误、异常 | 技术设计 → 实现 → 测试 |
| 重构 | 拆分、重构、迁移、解耦 | 技术设计 → 实现 → 测试 |
| 配置/小改动 | 调整、优化、配置 | 直接实现 → 验证 |
| **紧急热修** | **紧急、热修、hotfix、生产故障、P0** | **简化P3 → 紧急P4（压缩但不取消 Code Review） → P5必须补事后分析** |

当无法分类时，向用户确认后再路由。

### 执行入口

| 命令 | 触发场景 | 执行内容 |
|------|---------|---------|
| `/new-feature` | 新功能开发 | 完整五阶段流程（自动读取 workflows/full-lifecycle.md） |
| `/bug-fix` | 缺陷修复 | 技术设计 → 实现 → 测试 |
| `/close-loop` | 技术设计审批后 | P4 自动闭环：coding → review → testing → acceptance |
| `/init-project` | 框架接入新项目 | 引导式项目初始化配置 |
| 自然语言描述 | 用户直接描述需求 | 按上表分类后，自动执行对应 Skill |

当用户用自然语言描述需求时，按触发规则分类后，执行对应的 Skill。
每个 Skill 的第一步都会读取 `workflows/full-lifecycle.md`，确保流程被完整加载和执行。

---

## 2. 编排者边界

**当需要以下工作时，必须派发对应角色：**
- 编写需求文档 → 派发 pm-agent
- 技术方案设计 → 派发 arch-agent
- 编写业务代码 → 派发 dev-agent
- 编写测试用例 → 派发 qa-agent

**当需要以下工作时，编排者直接执行：**
- 配置修复、文档格式调整、git 操作、状态更新

**编排者必须做的事：**
- 理解用户需求并分类
- 派发 agent 并传递上下文
- 检查每个阶段的输入/输出契约
- 组织评审、记录评审结论
- 每次阶段变更时更新 `workspace/stage-status.json`

**编排者绝不能做的事：**
- 跳过输出验证直接进入下一阶段
- 替代专业角色完成其职责（标准及以上变更）

---

## 3. 仓库导航

| 路径 | 用途 |
|------|------|
| `.claude/agents/` | 角色提示词模板（pm/arch/dev/qa/reviewer/precheck/devops + evolution-policy） |
| `.claude/agents/agent-evolution-policy.md` | **框架自演进策略**（修改权限、触发时机、commit 约定） |
| `.claude/agents/devops-agent.md` | DevOps/部署 Agent（Dockerfile/docker-compose/CI-CD） |
| `.claude/skills/` | 工作流 Skill（new-feature / bug-fix / close-loop / init-project / health-check） |
| `.claude/hooks/check-coding-gate.sh` | Hook：代码写入前检查 stage-status（支持 legacyPaths 豁免） |
| `.claude/hooks/pre-implementation-check.sh` | Hook：实现阶段前检查 5 个设计文档是否存在且非空 |
| `.claude/hooks/post-stage-check.sh` | Hook：各阶段完成后检查对应产出物是否完整 |
| `.claude/rules/general.md` | 路径触发的架构编码规范（写代码时自动加载） |
| `docs/architecture.md` | 架构规范（4条核心原则 + 技术栈分层映射） |
| `docs/quality.md` | 质量标准 |
| `docs/specs/index.md` | 功能目录索引（活跃功能 + 已归档功能） |
| `docs/specs/{feature}/` | 功能规格说明（requirement/product/tech/test-plan/test-cases/review-log/test-report/test-result.json） |
| `docs/plans/active/` | 当前活跃的执行计划 |
| `docs/knowledges/index.md` | **知识库总索引（所有知识文件在此登记）** |
| `docs/knowledges/` | 知识库（domain/architecture/patterns/standards/lessons-learned/guides） |
| `docs/templates/` | 产物模板（含 tech-revision.md 技术方案迭代记录模板） |
| `workflows/full-lifecycle.md` | 完整生命周期工作流（含 Hotfix 路径、DYNAMIC_INJECT 协议） |
| `workspace/stage-status.json` | 流水线运行状态（v2 格式，含 metrics / archived / legacyPaths） |
| `workspace/memory.md` | 项目记忆（结构化：ADL / 经验教训 / 活跃约束 / 状态快照） |
| `workspace/cr-index.md` | CR/Bug 全局计数索引（各功能 OPEN 问题数，/health-check 统计用；详情在 docs/specs/{feature}/review-log.md） |
| `workspace/framework-health.md` | 框架自检记录（每 3 功能一次，/health-check 自动生成） |

---

## 4. 强制规则 R1-R7

**R1 角色分离**
当变更规模为标准及以上时，必须派发对应专业角色执行。禁止编排者直接编写业务代码或需求文档。

**R2 先计划后编码**
当变更规模为标准及以上时，必须先在 `docs/plans/active/` 创建执行计划，经确认后才能开始编码。

**R3 文档代码同步**
当代码发生变更时，必须同步更新关联文档。文档未同步 = 任务未完成。

**R4 追溯链**
每个产物必须包含 `traces_to` 字段，链接上游来源和下游依赖。当缺失追溯链时，评审不予通过。

**R5 门禁评审**
每个阶段的输出必须经评审团队审查。当存在 CRITICAL 级别问题时，必须修复后重新评审，不得跳过。

**R6 先验证后推进**
每个里程碑完成时，必须通过测试、lint、构建验证。当验证失败时，禁止进入下一阶段。

**R7 状态可见**
每次阶段变更时，必须更新 `workspace/stage-status.json`。当状态文件与实际进度不一致时，以实际为准并立即修正。

---

## 5. 架构约束摘要

详细规范见 `docs/architecture.md`，以下为四条技术栈无关的核心原则：

**P1 单向依赖（禁止反向）：**
层间依赖方向唯一，禁止循环。具体层名见 `docs/architecture.md` 的分层映射表。

```
数据定义层 ← 数据访问层 ← 业务逻辑层 ← 边界适配层 ← UI层
（箭头方向为允许的依赖方向：外层可以依赖内层）
```

**P2 边界校验：** 外部数据（HTTP/消息/文件）必须在边界适配层完成校验和类型转换，禁止原始外部数据进入业务逻辑层。

**P3 业务隔离：** 业务逻辑层不直接依赖具体框架或基础设施，通过接口抽象解耦，便于测试和替换。

**P4 错误统一：** 所有错误必须包含错误码（code）、消息（message）、上下文（context / details）三要素，通过统一 envelope 格式返回。

---

## 6. 模型路由（建议）

不同任务类型推荐使用不同模型，优化成本和质量：

| 任务类型 | 推荐模型 | 理由 |
|---------|---------|------|
| 需求分析 / 产品设计 (pm-agent) | Opus | 需要深度理解业务和创造性思考 |
| 技术设计 / 架构 (arch-agent) | Opus | 需要架构判断力和 Trade-off 分析 |
| 代码实现 (dev-agent) | Sonnet | 按明确设计实现，Sonnet 已足够 |
| 测试执行 (qa-agent) | Sonnet | 按用例执行，不需要创造性 |
| 代码审查 (reviewer-agent) | Opus | 需要判断力识别深层问题 |
| 代码搜索 / 探索 | Haiku | 最便宜，搜索探索任务足够 |
| 门禁审查（子代理） | Sonnet | 按审查 prompt 检查，Sonnet 足够 |

> 这是建议而非强制。单模型场景下忽略此表即可。

---

## 7. 框架自演进

详细的修改权限、触发时机和 commit 约定见 `.claude/agents/agent-evolution-policy.md`。

核心原则摘要：

**可自由修改：**
- agent 执行清单中的具体步骤（`.claude/agents/`）
- `docs/knowledges/` 中的知识条目
- `docs/templates/` 中的模板改进
- `.claude/hooks/` 检查条件和错误提示

**谨慎修改（需在 memory.md 记录理由）：**
- 核心角色职责定义（影响 Claude 对 agent 的调用判断）
- 本文件（CLAUDE.md）中的约束规则（R1-R7）

**禁止修改：**
- 用户已批准的需求内容
- 项目技术栈约束（由项目方决定）

---

## 8. 项目定制区

> 以下由具体项目填写。使用 `/init-project` 可自动完成大部分配置。

### 技术栈

| 层级 | 技术选型 | 版本 |
|------|----------|------|
| 语言 | | |
| 框架 | | |
| 数据库 | | |
| 构建工具 | | |

### 代码仓库路径

> 路径相对于 aifd-framework 目录。推荐结构下，业务代码目录与 aifd-framework 同级，路径以 `..` 开头。

| 仓库 | 路径 | 主分支 | 说明 |
|------|------|--------|------|
| | | main | |

### 分支策略

> 框架默认不强制分支管理。配置上方仓库表后，new-feature 和 close-loop 会自动管理特性分支。
> 未配置仓库时，以下策略不生效。

| 配置项 | 值 | 说明 |
|--------|-----|------|
| 分支命名规范 | `feature/{feature-name}` | 特性分支以功能名自动命名 |
| 创建时机 | P3 审批通过、进入 P4 前 | 仅在即将修改的仓库中创建 |
| 合并提醒 | P5 收尾阶段 | 提醒用户合并到主分支，不自动执行 |

### 构建验证命令

| 检查项 | 命令 | 通过标准 |
|--------|------|----------|
| Lint | | 零错误 |
| 单元测试 | | 全部通过 |
| 构建 | | 成功退出 |

### E2E 测试配置

> 以下配置用于 P4 Testing 阶段的 Tier 3 E2E 测试。仅全栈/前端项目需要填写。
> 使用 `/init-project` 时会自动填写。

| 配置项 | 值 |
|--------|-----|
| 前端启动命令 | |
| 前端地址 | |
| 后端启动命令 | |
| 后端健康检查 URL | |
| E2E 测试命令 | npx playwright test testing/e2e/ |

### 代码路径模式（Hook 守卫范围）

> 这些路径下的文件在没有活跃编码计划时会被 Hook 拦截。
> 使用 `/init-project` 时会自动填写。手动修改时同步更新 `.claude/hooks/check-coding-gate.sh`。

```
# 当前项目的代码路径模式（bash glob 格式）
src/*
backend/*
frontend/*
# [TODO: 根据项目实际目录结构添加或修改]
```
