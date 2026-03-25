# 项目记忆

> 本文件只记录高价值的项目级记忆。结构化分区，防止变成无序垃圾桶。
>
> **不在此记录的内容**：
> - Code Review 问题 → `workspace/code-review-log.md`
> - 框架自检结果 → `workspace/framework-health.md`
> - 流水线状态 → `workspace/stage-status.json`
> - 重要 ADR（需要 Trade-off 分析的决策）→ `docs/knowledges/architecture/`

---

## 区域 A：已确认的架构决策

> 格式：ADL-### | 决策内容 | 决策日期 | 是否仍然有效
> 规则：每条决策唯一编号，不重复记录。更新已有条目而非新增重复条目。

| ID | 决策 | 日期 | 有效 |
|----|------|------|------|
| ADL-001 | *[项目启动时填写第一条架构决策]* | — | — |

---

## 区域 B：经验教训

> 格式：L-### | 事件摘要 | 根因 | 教训 | 适用范围
> 规则：GC 阶段沉淀。可复用模式移入 `docs/knowledges/patterns/`。

### L-001：先查平台官方规格，再设计框架

- **事件**：v1-v9 的 agents/ 位置、frontmatter 字段名、skills frontmatter 全部不符合 Claude Code 官方标准
- **根因**：基于参考文章和第三方项目推断平台行为，从未查阅 Claude Code 官方文档
- **后果**：agents 无法被 Claude Code 原生发现和调度，model 字段无法生效，skills 无法自动触发
- **教训**：在设计任何基于平台的框架时，第一步必须查阅平台官方规格文档，而非基于假设或第三方实践推断
- **适用范围**：所有基于特定平台/工具链的框架设计

---

## 区域 C：当前活跃约束

> 记录临时性的、有时效性的约束。当约束失效时删除此处条目。
> 格式：约束内容 | 原因 | 预期解除时间

*（无活跃约束）*

---

## 区域 D：当前状态快照

> 每次启动新会话时快速了解项目状态。由编排者在阶段变更时更新。

- **上次更新**：2026-03-25
- **进行中的功能**：无（框架改进完成）
- **最近完成的功能**：enbrands-media2 借鉴改进（第三轮框架评审）
- **当前最大技术债**：结构化 JSON 评审输出（review-{stage}-{agent}.json），需修改 5 个 agent 输出契约，已推迟
- **下一步计划**：无活跃任务

---

## 区域 E：框架演进记录

### 2026-03-25 — enbrands-media2 借鉴改进（第三轮）

基于对 `D:\AIFD\enbrands-media2` 的深度分析，借鉴实践落地经验改进框架：

- **变更类型**：hook-new + agent-new + template-new + skill-update + workflow-update + claude-md-update
- **新增文件**：
  - `.claude/hooks/pre-implementation-check.sh` — 编码前强制检查 5 个设计文档是否存在
  - `.claude/hooks/post-stage-check.sh` — 阶段完成后验证产出物完整性
  - `.claude/agents/devops-agent.md` — DevOps/部署 Agent（Dockerfile、docker-compose、CI/CD、部署文档）
  - `.claude/agents/agent-evolution-policy.md` — 框架自演进策略独立文件（从 CLAUDE.md §7 提取并详细化）
  - `templates/tech-revision.md` — 技术方案迭代记录模板
- **修改文件**：
  - `CLAUDE.md §3 仓库导航` — 注册以上所有新文件
  - `CLAUDE.md §7 框架自演进` — 改为引用 agent-evolution-policy.md
  - `workflows/full-lifecycle.md §7.3` — 新增测试结构化输出要求（test-coverage-matrix.md + test-result.json）
  - `.claude/skills/close-loop.md` — 启动时强制执行 pre-implementation-check
- **触发原因**：enbrands-media2 实践发现 AIFD 缺失 DevOps 维度、预检 hook、技术方案迭代追踪、自演进独立文档
- **预期效果**：防止"没有测试用例就开始编码"；覆盖部署配置维度；自演进规则更可执行
