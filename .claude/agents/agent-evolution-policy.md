---
name: agent-evolution-policy
description: "框架自演进策略文档（仅供参考，不作为调用 agent）。定义框架组件的修改权限和演进协议。"
---

# Agent 自演进策略（agent-evolution-policy）

> 本文件定义 AIFD 框架自我优化的边界、触发条件和执行协议。
> 对应 CLAUDE.md §7，此处提供更详细的执行规范。

---

## 框架组件修改权限

### 可自由修改（执行层）

以下内容属于"执行细节"，可以在发现更好方式时自主优化：

| 组件 | 可修改内容 | 示例 |
|------|---------|------|
| `.claude/agents/*.md` | 执行清单中的具体步骤、质量检查清单、诊断命令 | 给 qa-agent 增加一个边界测试维度 |
| `.claude/skills/*.md` | 工作流步骤的顺序和细节、检查条件 | 优化 close-loop 的重试逻辑 |
| `.claude/hooks/*.sh` | 检查路径、检查条件、错误提示文案 | 扩展 pre-implementation-check 的检查项 |
| `docs/knowledges/` | 添加新知识条目、更新已有条目 | 沉淀新的经验教训 |
| `templates/` | 模板字段、格式、示例内容 | 根据实践改进 requirement.md 模板 |
| `workspace/memory.md` | 新增决策记录、更新项目状态 | 记录架构决策 |

### 谨慎修改（需说明理由）

以下内容属于"框架约定"，修改需明确说明理由并在 commit message 中记录：

| 组件 | 谨慎修改的部分 | 原因 |
|------|-------------|------|
| `.claude/agents/*.md` | 角色定位、核心职责定义、调用边界 | 影响 Claude 对 agent 的理解和调用决策 |
| `.claude/skills/*.md` | 阶段顺序、Gate 评审要求、退出条件 | 影响质量门禁的有效性 |
| `CLAUDE.md` §1-§7 | 触发规则、编排者边界、强制规则 R1-R7 | 影响整个框架的核心行为 |
| `docs/architecture.md` 框架通用区 | P1-P4 架构原则 | 跨项目通用，不应随单个项目改变 |

**谨慎修改协议**：
1. 在修改前，说明"为什么当前设计不够好"
2. 在 commit message 中记录变更原因（格式见下方）
3. 更新 `workspace/memory.md` 中的相关决策记录

### 禁止修改

| 内容 | 原因 |
|------|------|
| 用户已审批的需求文档（requirement.md、product.md） | 不得擅自更改用户确认的需求 |
| 项目技术栈约束（CLAUDE.md §8 技术栈表） | 技术选型由项目方决定 |
| 已归档的执行计划（docs/plans/completed/） | 历史记录，不可篡改 |
| 已关闭的 PR/CR 结论（workspace/code-review-log.md 中 RESOLVED 条目） | 审查结论不可追溯修改 |

---

## 演进触发时机

框架自演进应在以下时机发生，而非随机修改：

| 时机 | 说明 | 可演进的内容 |
|------|------|------------|
| **P5 GC 完成后** | 每次功能交付都是积累经验的机会 | templates/、knowledge/、agent 执行清单 |
| **发现重复问题** | 同一类问题出现 2 次以上 | hooks 检查条件、agent 质量清单 |
| **agent 执行失败** | agent 在某步骤反复出错或产出质量差 | 该 agent 的执行步骤和质量标准 |
| **/health-check 发现问题** | 框架健康检查指出某个模式需要改进 | 对应组件 |
| **lessons-learned 新增条目** | 新教训需要在框架中"固化"，防止复发 | 相关 templates/ 或 .claude/rules/ |

**不应触发自演进的情况**：
- 临时性、项目特定的一次性调整（应记录在 memory.md，不改 agent）
- 对框架设计有争议但尚未验证的想法（先在 memory.md 记录，验证后再固化）

---

## 演进记录协议

### 变更记录格式

每次框架自演进必须在 `workspace/memory.md` 中追加记录：

```markdown
## 框架演进记录

### {日期} — {变更标题}

- **变更类型**：agent-improvement / skill-update / hook-fix / template-update / knowledge-add
- **变更文件**：{具体文件路径}
- **触发原因**：{为什么需要这个变更？来自哪次实践？}
- **变更内容摘要**：{改了什么，一句话描述}
- **预期效果**：{这个变更应该解决什么问题？}
```

### Git Commit 约定（适用于纳入 git 管理的项目）

框架自演进类的 commit 使用专用前缀：

```
evolution: [agent/skill/hook/template/knowledge] {具体变更描述}

示例：
evolution: [agent] qa-agent 增加 API 鉴权测试维度
evolution: [hook] pre-implementation-check 增加 exec-plan 检查
evolution: [template] requirement.md 新增 API 契约字段
evolution: [knowledge] 沉淀 JWT 鉴权最佳实践
```

---

## 演进质量标准

自演进不是随意修改，每次变更前自问：

1. **这个变更能防止已知问题复发吗？** — 如果是，这是好的演进
2. **这个变更会让框架更难理解或使用吗？** — 如果是，谨慎
3. **这个变更是否会影响其他正在进行的功能？** — 检查 stage-status.json
4. **这个变更是否有配套的文档更新？** — 框架文件改了，相关说明也要同步

---

## 与 CLAUDE.md 的关系

本文件是 `CLAUDE.md §7 框架自演进` 的详细执行规范。两者关系：
- `CLAUDE.md §7`：框架自演进的核心原则（What & Why）
- 本文件：具体的执行边界和操作协议（How）

当本文件与 `CLAUDE.md §7` 有冲突时，以 `CLAUDE.md §7` 为准。
