---
name: claude-code-spec-check
description: "当新增或修改 .claude/ 下的 agents、skills、hooks、CLAUDE.md、rules 配置文件时使用。"
user-invocable: true
---

# /claude-code-spec-check — Claude Code 官方规格速查与验证

> 当新增或修改 agents、skills、hooks 时，用本技能验证是否符合官方标准。

---

## 1. Skills 规格

**位置**：`.claude/skills/{skill-name}.md`（项目级）或 `~/.claude/skills/{skill-name}.md`（全局级）

**必填 frontmatter**：

```yaml
---
name: slug-format-lowercase-hyphens  # 必填，小写+连字符，最长 64 字符
description: "做什么 + 什么时候用"     # 必填，最长 1024 字符，决定自动触发时机
---
```

**可选 frontmatter**：

```yaml
disable-model-invocation: false  # true = 仅 /命令 触发，Claude 不会自动调用
user-invocable: true             # false = 仅 Claude 内部调用，用户无法用 /命令
allowed-tools: [Bash, Read, Write]  # 限制可用工具
version: "1.0.0"
```

**触发方式**：
- `/skill-name` — 用户手动触发（基于 `name` 字段）
- 自动触发 — Claude 根据 `description` 匹配当前任务自动调用

**正文**：Markdown 指令，Claude 按此执行

---

## 2. Agents 规格

**位置**：`.claude/agents/{agent-name}.md`（项目级）或 `~/.claude/agents/{agent-name}.md`（全局级）

**必填 frontmatter**：

```yaml
---
name: agent-display-name     # 必填，Agent 显示名
description: "职责和使用场景"  # 必填，描述清楚什么时候调度
---
```

**可选 frontmatter**：

```yaml
model: opus          # opus / sonnet / haiku，指定该 Agent 使用的模型
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]  # 限制可用工具
memory: true         # 启用持久化记忆（~/.claude/agents/{name}/memory/）
```

**关键设计**：
- `model` 字段直接实现模型路由（无需在 CLAUDE.md 中额外配置）
- `allowed-tools` 实现最小权限原则（pm-agent 不需要 Bash，reviewer 不需要 Write）
- Claude Code 会原生发现 `.claude/agents/` 下的 Agent 并可通过 Agent 工具调度

**正文**：系统提示词，定义 Agent 的行为、角色、输入输出契约

---

## 3. Hooks 规格

**位置**：`.claude/settings.json`（项目级）或 `~/.claude/settings.json`（全局级）

**支持的事件类型**：

| 事件 | 触发时机 | 典型用途 |
|------|---------|---------|
| `PreToolUse` | 工具执行前 | 阻止未授权操作（exit 2 = 拒绝） |
| `PostToolUse` | 工具执行后 | 自动格式化、运行测试 |
| `Stop` | Claude 完成响应时 | 最终验证、构建检查 |
| `PreCompact` | 上下文压缩前 | 保存关键信息 |
| `SessionStart` | 会话启动时 | 初始化环境 |
| `SessionEnd` | 会话结束时 | 清理资源 |
| `Notification` | 通知发送时 | 自定义通知 |
| `UserPromptSubmit` | 用户提交消息时 | 输入预处理 |

**格式**：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash -c 'your-check-command'"
      }
    ]
  }
}
```

**拒绝工具调用**（PreToolUse）：
- 退出码 2 = 拒绝
- 可输出 JSON：`{"permissionDecision": "deny", "permissionDecisionReason": "原因"}`

---

## 4. CLAUDE.md 规格

**位置**：项目根目录 `CLAUDE.md`

**加载规则**：
- Claude Code 自动递归向上查找并加载所有层级的 CLAUDE.md
- 子目录的 CLAUDE.md 仅在 Claude 读取该目录文件时加载
- 兄弟目录的 CLAUDE.md 不会交叉加载
- 全局配置：`~/.claude/CLAUDE.md`（对所有会话生效）

**优先级**（从高到低）：
1. 用户显式指令（CLAUDE.md + 对话中的要求）
2. Skills 指令
3. 系统默认提示

**最佳实践**：
- 保持精简（~120-160 行），只写项目特定的指令
- 如果 Claude 不写指令也能做对，就删掉那条指令
- 关键规则如果担心上下文压缩后丢失 → 改用 hooks 实现（hooks 每次都触发）
- 通用建议（"写干净的代码"）浪费 token，不要写

---

## 5. 验证清单

当新增或修改 `.claude/` 下的文件时，逐项检查：

### Skills 验证
- [ ] 文件位于 `.claude/skills/` 目录
- [ ] 有 YAML frontmatter，包含 `name` 和 `description`
- [ ] `name` 全小写+连字符，≤64 字符
- [ ] **`description` 只写触发条件**（"当…时使用"），**不写流程概述**（见下方 description 规范）
- [ ] 有副作用的操作（如写文件、执行命令）设置了 `disable-model-invocation: true`

### Agents 验证
- [ ] 文件位于 `.claude/agents/` 目录
- [ ] 有 YAML frontmatter，包含 `name` 和 `description`
- [ ] 工具字段使用 `allowed-tools`（不是 `tools`）
- [ ] 指定了 `model`（opus/sonnet/haiku）
- [ ] `allowed-tools` 符合最小权限原则
- [ ] **`description` 只写触发条件**，不写职责概述（如"负责…"格式禁止）

### Rules 验证
- [ ] 文件位于 `.claude/rules/` 目录
- [ ] 有 YAML frontmatter，包含 `paths` 字段（路径 glob 数组）
- [ ] `paths` 字段精确描述适用范围（不写 `["**"]` 全局匹配）
- [ ] 内容为 always-on 规范（不是工作流），适合按路径自动加载
- [ ] 内容已从 CLAUDE.md 中拆分（不在两处重复）

### Hooks 验证
- [ ] 配置在 `.claude/settings.json` 中
- [ ] `matcher` 正则匹配正确的工具名
- [ ] `command` 使用 `bash -c` 包裹
- [ ] 阻止操作使用 exit 2（不是 exit 1）

### CLAUDE.md 验证
- [ ] 位于项目根目录
- [ ] 不超过 160 行
- [ ] 不包含通用建议（只包含项目特定指令）
- [ ] 关键规则有 hooks 兜底（不仅靠文本指令）
- [ ] 已拆分到 `.claude/rules/` 的内容不在此重复

---

## 6. Description 字段规范（重要）

**核心原则**：`description` 字段决定 Claude 何时自动调用此 skill/agent。

### 正确格式（只写触发条件）

```yaml
description: "当用户提出新功能开发需求时使用。"
description: "当代码实现完成后需要进行审查时使用。"
description: "当需要制定测试计划或执行测试验证时使用。"
```

### 错误格式（包含流程概述 → 禁止）

```yaml
# ❌ 错误：Claude 会把前半句当指令执行，绕过正文
description: "触发完整五阶段研发流程（需求→设计→实现）。当用户提出新功能需求时使用。"

# ❌ 错误：职责概述不是触发条件
description: "产品经理，负责需求分析、产品设计、功能验收。"

# ❌ 错误：混合了角色定义和触发场景
description: "通用开发者，按执行计划实现代码（可按技术栈替换）。"
```

**为什么重要**：Claude 使用 `description` 字段来决定是否自动调用这个 skill/agent。如果 description 包含了"触发完整流程"这类动作性语句，Claude 会照着 description 行动，而不去读完整的 skill 正文——导致流程被错误简化执行。
