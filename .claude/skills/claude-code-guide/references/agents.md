# Agents（子代理）完整规格

## 文件位置

```
.claude/agents/agent-name.md     ← 项目级（可提交到 git）
~/.claude/agents/agent-name.md   ← 全局级（所有项目可用）
```

单文件格式即可，无需文件夹结构。

---

## Frontmatter 完整字段

```yaml
---
name: agent-name                      # 必填：人类可读名称，用于 Agent 工具调用
description: "职责描述 + 何时调度"    # 必填：Claude 根据此字段决定何时自动调度
model: opus                           # 可选：haiku / sonnet / opus（具体模型 ID 也可以）
allowed-tools: [Read, Write, Bash]    # 可选：最小权限工具列表
memory: true                          # 可选：启用持久化记忆
---

[Agent 系统提示词 / 角色定义，Markdown 正文]
```

---

## 模型选择建议

| 角色类型 | 推荐模型 | 理由 |
|---------|---------|------|
| 需求分析、产品设计 | `opus` | 需要深度理解和创造性思考 |
| 技术架构设计 | `opus` | 需要架构判断力和 Trade-off 分析 |
| 代码实现 | `sonnet` | 按明确设计实现，Sonnet 已足够 |
| 测试执行 | `sonnet` | 按用例执行，不需要创造性 |
| 代码审查 | `opus` | 需要判断力识别深层问题 |
| 搜索/探索 | `haiku` | 最便宜，搜索探索已足够 |

---

## allowed-tools 最小权限原则

```yaml
# 产品经理 — 不需要执行代码
allowed-tools: [Read, Grep, Glob, Write, Edit, AskUserQuestion]

# 技术架构师 — 需要读写文档，可能需要执行命令验证
allowed-tools: [Read, Grep, Glob, Write, Edit, Bash]

# 开发者 — 需要完整工具集
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]

# 测试工程师 — 同开发者
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]

# 代码审查 — 只读，禁止修改代码
allowed-tools: [Read, Grep, Glob, Bash]
```

---

## Agent 调度机制

**自动调度**：Claude 读取所有 `.claude/agents/` 下的 agent 的 `description`，根据当前任务内容自动匹配并派发。

**显式调度**：在 skill 或指令中明确指定 agent：
```markdown
以 pm-agent 的角色执行需求分析
读取 .claude/agents/arch-agent.md，以 arch-agent 模式 A 执行
```

**Agent 工具调度**：Claude 可以通过 Agent 工具显式启动 subagent：
```
# Claude 内部通过 Agent 工具调用
subagent_type: "arch-agent"
prompt: "分析以下变更的技术可行性..."
```

---

## 完整示例

```yaml
---
name: security-auditor
description: "安全审计专家，负责识别代码中的安全漏洞（OWASP Top 10、注入攻击、认证缺陷等）。当需要对代码进行安全审查时使用。"
model: opus
allowed-tools: [Read, Grep, Glob, Bash(git log*)]
---

# 安全审计 Agent

## 角色职责

你是一名资深安全工程师，专注于：
- 识别 OWASP Top 10 安全漏洞
- 检查认证与授权缺陷
- 发现注入攻击风险（SQL、命令注入、XSS）
- 审查敏感数据处理

## 输出格式

按 CRITICAL / HIGH / MEDIUM / LOW 分级输出问题清单：

```
[CRITICAL] 文件:行号 — 问题描述
  复现：...
  修复建议：...
```

## 约束

- 只读不写，不直接修改代码
- 发现 CRITICAL 问题时立即标红并停止继续审查，等待人工确认
```

---

## 项目级 vs 全局级

| | 项目级 `.claude/agents/` | 全局级 `~/.claude/agents/` |
|-|--------------------------|---------------------------|
| 作用范围 | 仅当前项目 | 所有项目 |
| 版本控制 | 可提交，团队共享 | 本地个人 |
| 适用场景 | 项目特定角色 | 通用工具 agent |
