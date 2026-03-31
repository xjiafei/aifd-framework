# AIFD — AI驱动全流程研发框架

## 简介

AIFD (AI-Driven Full-lifecycle Development) 是一个基于 Claude Code 的全流程研发框架，覆盖需求分析、产品设计、技术设计、代码实现、测试验证完整研发流程。

核心理念：**仓库即工作环境，所有事实、规则、计划、验证标准沉淀在仓库中。**

Agent 不再是"接收指令的工具"，而是在一套可执行协议下自主运作的工程角色。每个角色有明确的输入、输出、约束和验证标准，通过仓库中的文件进行协同。

## 设计哲学

| 原则 | 说明 |
|------|------|
| **可执行协议 > 参考文档** | CLAUDE.md 中的规则是硬性约束，Agent 必须遵守，而非建议性参考 |
| **硬拦截 + 软控制** | 关键节点设置不可跳过的检查点（Hook 门禁），其余通过 prompt 引导 |
| **角色分离 + 两级审查** | 编排者统筹，专业 Agent 执行，自动预检 + 人工复核确保输出质量 |
| **Close-Loop 闭环 + 有限次循环** | 每个阶段形成闭环，设置最大重试次数防止无限循环 |
| **最小起步，按需增长** | 从最简配置开始，根据项目需要逐步添加规范和约束 |
| **单源事实，追溯可验证** | 每个决策都有文档记录，可追溯到需求来源（traces_to 链接） |

## 框架结构

```
aifd-framework/
├── CLAUDE.md                        # 可执行协议（编排者入口，所有规则在此）
├── README.md                        # 框架介绍和快速开始
│
├── .claude/
│   ├── agents/                      # Agent 角色提示词模板
│   │   ├── pm-agent.md              # 产品经理（需求分析、产品设计、功能验收）
│   │   ├── arch-agent.md            # 架构师（技术设计、技术验收）
│   │   ├── dev-agent.md             # 开发者（代码实现）
│   │   ├── qa-agent.md              # 测试工程师（测试计划、测试执行）
│   │   ├── reviewer-agent.md        # 代码审查（两阶段：需求合规 + 代码质量）
│   │   └── precheck-agent.md        # 文档预检（Gate 评审前结构性校验）
│   │
│   ├── skills/                      # 工作流 Skill（/斜杠命令）
│   │   ├── new-feature.md           # /new-feature — 完整五阶段新功能流程
│   │   ├── bug-fix.md               # /bug-fix — 缺陷修复流程
│   │   ├── close-loop.md            # /close-loop — P4 自动闭环（coding→review→test→accept）
│   │   ├── init-project.md          # /init-project — 项目初始化向导
│   │   └── health-check.md          # /health-check — 框架健康检查
│   │
│   ├── rules/
│   │   └── general.md               # 路径触发的架构编码规范（写代码时自动加载）
│   │
│   └── hooks/
│       └── check-coding-gate.sh     # Hook 守卫：无活跃编码计划则拦截代码写入
│
├── workflows/
│   └── full-lifecycle.md            # 完整生命周期参考文档（Triage、P1-P5 详细规程）
│
├── docs/
│   ├── architecture.md              # 架构规范（框架原则 + 项目定制区，由 /init-project 填写）
│   ├── quality.md                   # 质量标准
│   ├── templates/                   # 产物模板（各阶段文档的标准结构）
│   │   ├── requirement.md           # 需求文档模板
│   │   ├── product.md               # 产品设计模板
│   │   ├── tech-design.md           # 技术设计模板
│   │   ├── tech-revision.md         # 技术方案迭代记录模板
│   │   ├── exec-plan.md             # 执行计划模板
│   │   ├── test-plan.md             # 测试计划模板
│   │   └── test-cases.md            # 测试用例模板
│   ├── specs/
│   │   ├── index.md                 # 功能目录索引（活跃功能 + 已归档功能）
│   │   └── {feature}/               # 各功能的规格文档（由各阶段 Agent 产出）
│   ├── plans/
│   │   ├── active/                  # 当前活跃执行计划
│   │   └── completed/               # 已归档执行计划
│   └── knowledges/
│       ├── index.md                 # 知识库总索引（所有知识文件在此登记）
│       ├── domain/                  # 业务领域知识（领域规则、术语表）
│       ├── architecture/            # 架构决策记录 ADR
│       ├── patterns/                # 可复用代码模式
│       ├── standards/               # 编码规范（按技术栈）
│       ├── lessons-learned/         # 经验教训（P5 GC 阶段沉淀）
│       └── guides/                  # 操作指南（如存量项目迁移）
│
├── examples/                        # 技术栈参考示例（供 /init-project 参考）
│   ├── java-spring-boot/            # Java Spring Boot 示例配置
│   └── vue-frontend/                # Vue 前端示例配置
│
└── workspace/                       # 运行时状态（由框架自动维护）
    ├── stage-status.json            # 流水线状态（由 /init-project 初始化，各阶段自动更新）
    ├── memory.md                    # 项目记忆（ADL、经验教训、活跃约束）
    ├── code-review-log.md           # Code Review 问题清单（OPEN/RESOLVED 状态）
    └── framework-health.md          # 框架健康检查记录
```

## 快速开始

### 前置要求

- Claude Code CLI 已安装
- 项目代码仓库已准备好（或准备新建）

### 场景 A：新项目从零开始

**第 1 步：克隆框架**

```bash
git clone <aifd-framework-url> my-project-aifd
cd my-project-aifd
```

**第 2 步：运行初始化向导**

在 Claude Code 中执行：

```
/init-project
```

向导会引导你填写：项目名称、技术栈、代码仓库路径、构建命令。完成后自动配置：
- `CLAUDE.md` 项目定制区（技术栈表、构建命令）
- `docs/architecture.md` 技术栈分层映射
- `.claude/agents/dev-agent.md` 等 agent 的技术约束注入区
- `workspace/stage-status.json` 初始状态文件
- `.claude/hooks/check-coding-gate.sh` 代码路径守卫

**第 3 步：开始第一个功能**

```
/new-feature
```

输入功能描述，框架自动进入 P1（需求分析）→ P2（产品设计）→ P3（技术设计）→ 等待审批 → P4（实现）→ P5（收尾）。

---

### 场景 B：已有项目接入（含多 git 仓库）

**核心思路**：AIFD 框架本身作为独立的"编排仓库"，Claude Code 在此仓库中运行，通过相对路径访问和修改业务仓库的代码。

**目录结构**（以前后端分离、各有多个服务仓库为例）：

```
my-project/                          # 项目根目录（不是 git 仓库）
├── aifd-framework/                  ← AIFD 编排仓库（Claude Code 的工作目录）
│   ├── CLAUDE.md
│   ├── .claude/
│   ├── docs/                        ← 所有设计文档、规格、知识库在此沉淀
│   └── workspace/
│
├── backend/                         ← 后端分组目录（非 git 仓库，仅用于分组）
│   ├── auth-service/                ← 独立 git 仓库
│   ├── user-service/                ← 独立 git 仓库
│   └── order-service/               ← 独立 git 仓库
│
└── frontend/                        ← 前端分组目录（非 git 仓库，仅用于分组）
    ├── web-app/                     ← 独立 git 仓库
    └── admin-panel/                 ← 独立 git 仓库
```

**第 1 步：克隆框架**

```bash
mkdir my-project && cd my-project
git clone <aifd-framework-url> aifd-framework
```

**第 2 步：在编排仓库中打开 Claude Code**

```bash
cd aifd-framework
# 此处启动 Claude Code，所有 Agent 和 Hook 均以此目录为根
```

**第 3 步：运行初始化向导，自动克隆业务仓库**

```
/init-project
```

向导会询问是否有远程仓库需要克隆。提供仓库信息后，自动完成：
- 按分组创建 `../backend/`、`../frontend/` 等类别目录
- 将每个仓库克隆到对应子目录（如 `../backend/auth-service`）
- 配置 `CLAUDE.md §8` 中的代码仓库路径表和分支信息
- 配置 `legacyPaths`（遗留代码路径豁免，存量代码不受 Hook 拦截）
- 为核心模块创建简化版 `tech.md`（作为追溯起点）

**第 4 步：从任意阶段切入**

- 已有架构但需要新功能 → `/new-feature`
- 存在 Bug 需要修复 → `/bug-fix`
- 技术设计已完成，直接开始编码 → `/close-loop`

> **注意**：Claude Code 通过相对路径（如 `../backend/auth-service/src/...`）读写业务仓库文件。各业务仓库保持独立，各自管理 git 历史和 CI/CD，编排仓库只负责流程协调和文档沉淀。

---

## 全流程概览

```
用户输入
  │
  ▼
┌──────────────────────────────────────────────────┐
│  Triage 分流                                      │
│  配置/小改动 → 直接实现 → 验证                    │
│  Bug/重构   → P3(技术设计) 开始                   │
│  新功能     → 完整 P1→P2→P3→P4→P5               │
│  紧急热修   → 简化P3 → 紧急P4 → P5补事后分析      │
└──────────────────────────────────────────────────┘
       │ 新功能路径
       ▼
┌─────────────┐  Gate  ┌─────────────┐  Gate  ┌─────────────┐
│  P1 需求分析  │──评审──→│  P2 产品设计  │──评审──→│  P3 技术设计  │
│  (pm-agent) │        │  (pm-agent) │        │ (arch-agent)│
└─────────────┘        └─────────────┘        └──────┬──────┘
                                                      │ Gate + 人工审批
                                                      ▼
                                              ┌───────────────────────────┐
                                              │  P4 /close-loop 自动闭环  │
                                              │  coding → review → test   │
                                              │  → acceptance（最多3轮）   │
                                              └──────────────┬────────────┘
                                                             │ 全部通过
                                                             ▼
                                                      ┌─────────────┐
                                                      │  P5 收尾 GC  │
                                                      │  归档 + 知识  │
                                                      │  沉淀 + 索引  │
                                                      └─────────────┘
```

每个阶段都有明确的**入口条件**、**执行步骤**、**门禁评审**和**出口标准**。详细规程见 `workflows/full-lifecycle.md`。

## 关键机制说明

### Hook 门禁

`.claude/hooks/check-coding-gate.sh` 监控代码文件写入。在 `workspace/stage-status.json` 未显示当前功能处于 `stage=implementation, status=running` 时，会阻止代码写入，防止绕过前置设计流程。

存量项目中，遗留代码路径通过 `legacyPaths` 配置豁免，核心业务代码不得豁免。

### Agent 角色分工

| Agent | 核心职责 | 调用时机 |
|-------|---------|---------|
| pm-agent | 需求分析、产品设计、功能验收 | P1、P2、P4 验收 |
| arch-agent | 技术设计、exec-plan、技术验收 | P3、P4 验收 |
| dev-agent | 代码实现、Bug 修复 | P4 Coding |
| qa-agent | 测试计划、测试用例、测试执行 | P3、P4 Testing |
| reviewer-agent | 两阶段代码审查（需求合规→代码质量） | P4 Code Review |
| precheck-agent | 文档结构预检 | 各阶段 Gate 前自动调用 |

### 知识库（docs/knowledges/）

项目积累的可复用知识，分六类存放：
- `domain/` — 业务领域知识
- `architecture/` — 架构决策记录（ADR）
- `patterns/` — 可复用代码模式
- `standards/` — 编码规范
- `lessons-learned/` — 经验教训（P5 GC 阶段自动沉淀）
- `guides/` — 操作指南

所有知识文件在 `docs/knowledges/index.md` 统一登记。Agent 在 P1/P3/P4 开始前强制加载相关知识。

## 如何添加新技术栈

1. **参考示例**：查看 `examples/` 下对应技术栈示例（如 `java-spring-boot/`）
2. **更新 Agent 注入区**：在 `.claude/agents/dev-agent.md` 的 `<!-- DYNAMIC_INJECT -->` 区域填入技术约束（或运行 `/init-project` 自动完成）
3. **创建编码规范**：在 `docs/knowledges/standards/` 下创建 `{tech}-standards.md`，并在 `docs/knowledges/index.md` 登记
4. **更新架构文档**：在 `docs/architecture.md` 的项目定制区填写分层映射表

## 多仓库支持

AIFD 支持多个业务仓库的统一编排。推荐使用**分组子目录**结构，每个仓库一个独立目录。

### 推荐：分组子目录（每仓库独立，按类别分组）

```
my-project/                  # 项目根目录（不是 git 仓库）
├── aifd-framework/          # 编排仓库（Claude Code 工作目录）
├── backend/                 # 后端分组目录（非 git，仅分组）
│   ├── auth-service/        # 独立 git 仓库
│   ├── user-service/        # 独立 git 仓库
│   └── order-service/       # 独立 git 仓库
└── frontend/                # 前端分组目录（非 git，仅分组）
    ├── web-app/             # 独立 git 仓库
    └── admin-panel/         # 独立 git 仓库
```

Claude Code 通过相对路径 `../backend/auth-service/src/...` 访问业务代码。`/init-project` 会自动完成目录创建和仓库克隆。

### 备选：扁平并列（仓库较少时适用）

```
my-project/                  # 项目根目录（不是 git 仓库）
├── aifd-framework/          # 编排仓库（Claude Code 工作目录）
├── backend/                 # 后端仓库（独立 git）
├── frontend-web/            # Web 前端仓库（独立 git）
└── mobile-app/              # 移动端仓库（独立 git，如有）
```

适合仓库数量少（3 个以内）、无需按类别分组的情况。

### 编排规则

| 原则 | 说明 |
|------|------|
| 单源事实 | 所有设计文档、决策记录、追溯链路只在编排仓库维护 |
| 仓库独立 | 各业务仓库保持独立 git 历史，不在编排仓库中提交业务代码 |
| 接口前置 | 跨仓库接口契约在 P3 技术设计阶段确定，作为各仓库开发的输入 |
| 路径配置 | `CLAUDE.md §8` 代码仓库路径表中登记所有业务仓库的相对路径 |

## License

MIT
