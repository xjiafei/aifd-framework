---
name: claude-code-guide
description: "Claude Code 扩展开发指南（官方规格）。当需要创建或修改 agents、skills、commands、hooks、settings.json、CLAUDE.md 时使用。包含完整的字段规格、格式示例和常见陷阱。"
user-invocable: true
disable-model-invocation: false
---

# Claude Code 扩展开发指南

> 基于官方文档，覆盖 Skills、Agents、Commands、Hooks、Settings、CLAUDE.md 全部规格。

---

## 快速导航

| 需求 | 参考文件 |
|------|---------|
| 创建 skill（/命令） | `references/skills.md` |
| 创建自定义 agent（子代理） | `references/agents.md` |
| 创建 slash command | `references/commands.md` |
| 配置 hooks（自动化钩子） | `references/hooks.md` |
| 配置 settings.json（权限/环境变量） | `references/settings.md` |
| CLAUDE.md + Memory 文件 | `references/claude-md.md` |

---

## 文件位置速查表

| 类型 | 项目级（version control） | 全局级（个人） |
|------|--------------------------|---------------|
| Settings | `.claude/settings.json` | `~/.claude/settings.json` |
| 本地覆盖（不提交） | `.claude/settings.local.json` | `~/.claude/settings.local.json` |
| Commands | `.claude/commands/` | `~/.claude/commands/` |
| Skills | `.claude/skills/` | `~/.claude/skills/` |
| Agents | `.claude/agents/` | `~/.claude/agents/` |
| Rules | `.claude/rules/` | `~/.claude/rules/` |
| Project Instructions | `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Memory（自动管理） | 不提交 | `~/.claude/projects/<proj>/memory/MEMORY.md` |

---

## Frontmatter 字段汇总

### Skills / Commands 通用字段

```yaml
---
name: kebab-case-name          # 必填，≤64字符，小写+连字符，须与目录名一致
description: "做什么+何时用"   # 必填，≤1024字符，无XML标签，决定自动触发时机
user-invocable: true           # 可选，false=不出现在/菜单，仅Claude内部调用
disable-model-invocation: true # 可选，true=仅/命令触发，Claude不自动调用（副作用操作必须设true）
allowed-tools: [Bash, Read]    # 可选，限制可用工具，无需每次授权
model: sonnet                  # 可选，haiku/sonnet/opus/inherit，覆盖默认模型
argument-hint: "[arg1] [arg2]" # 可选，自动补全提示
version: "1.0.0"               # 可选，仅元数据
mode: false                    # 可选，标记为模式命令
---
```

### Agents 专属字段

```yaml
---
name: agent-name               # 必填
description: "职责与使用场景"   # 必填，Claude依此判断何时调度
model: opus                    # 可选，haiku/sonnet/opus
allowed-tools: [Read, Write]   # 可选，最小权限原则
memory: true                   # 可选，启用持久化记忆
---
```

---

## Hooks 退出码（关键）

| 退出码 | 含义 | 适用事件 |
|--------|------|---------|
| `0` | 成功，正常继续 | 所有 |
| `2` | **拒绝**，终止工具调用并报错 | PreToolUse、UserPromptSubmit |
| 其他 | 非阻塞错误，仅记录日志 | 所有 |

> **常见错误**：用 `exit 1` 拒绝操作不起作用，必须用 `exit 2`。

---

## 诊断清单

新建或修改 `.claude/` 配置时逐项检查：

**Skill/Command**
- [ ] `name` 小写+连字符，≤64字符，与目录名一致
- [ ] `description` 说明"做什么"和"何时用"，≤1024字符
- [ ] 有副作用操作设了 `disable-model-invocation: true`
- [ ] 文件夹格式时主文件命名为 `SKILL.md`（大写，大小写敏感）

**Agent**
- [ ] 位于 `.claude/agents/`
- [ ] 有 `name` + `description`
- [ ] 使用 `allowed-tools`（不是 `tools`）
- [ ] 指定了 `model`
- [ ] `allowed-tools` 符合最小权限

**Hook**
- [ ] 拒绝操作用 `exit 2`（不是 `exit 1`）
- [ ] `matcher` 正则匹配正确的工具名
- [ ] `command` 用 `bash -c` 包裹

**CLAUDE.md**
- [ ] 不超过200行
- [ ] 只写项目特定指令，不写通用建议
- [ ] 关键规则用 hooks 兜底（文本指令可能被上下文压缩丢失）

---

详细规格和示例见 `references/` 下对应文件。
