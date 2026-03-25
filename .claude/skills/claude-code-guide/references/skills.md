# Skills 完整规格

## 文件结构

两种格式，推荐文件夹格式：

```
# 单文件格式（简单 skill）
.claude/skills/skill-name.md

# 文件夹格式（推荐，支持多文件组织）
.claude/skills/skill-name/
├── SKILL.md              ← 必须大写，大小写敏感
├── references/           ← 详细参考文档
├── scripts/              ← 辅助脚本
├── assets/               ← 模板、示例文件
└── examples/             ← 预期输出示例
```

> **重要**：文件夹格式时主文件必须命名为 `SKILL.md`（全大写），名称大小写敏感。

---

## Frontmatter 完整字段

```yaml
---
name: skill-name                  # 必填：≤64字符，小写+连字符，与目录名一致
description: "做什么 + 何时用"    # 必填：≤1024字符，无XML标签，Claude用此决定自动触发时机
user-invocable: true              # 可选：false=不在/菜单显示（仅Claude内部调用）
disable-model-invocation: false   # 可选：true=只允许/命令触发，Claude不自动调用
allowed-tools: [Bash, Read, Write] # 可选：工具白名单，无需每次授权（支持通配符）
model: inherit                    # 可选：haiku / sonnet / opus / inherit（默认inherit）
argument-hint: "[feature-name]"   # 可选：自动补全提示，显示在/命令后
version: "1.0.0"                  # 可选：版本号，仅元数据
mode: false                       # 可选：标记为"模式命令"
---
```

---

## allowed-tools 格式

```yaml
# 基本格式
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob]

# 带参数模式匹配
allowed-tools: [Bash(git *), Write(docs/**), Read(*.md)]

# 多工具混合
allowed-tools: [Bash(npm run *), Edit, Write(src/**), Read]
```

---

## user-invocable vs disable-model-invocation 区别

| 字段 | 值 | 效果 |
|------|-----|-----|
| `user-invocable` | `false` | Skill 不出现在 `/` 菜单，用户无法手动触发，但 Claude 仍可自动调用 |
| `disable-model-invocation` | `true` | Claude 完全看不到此 skill，只能通过 `/命令` 手动触发 |

**何时用 `disable-model-invocation: true`：**
- 会触发不可逆操作的 skill（deploy、send message、delete）
- 会修改大量文件的 skill（close-loop、migrate）
- 流程性 skill（new-feature、bug-fix）— 防止对话中意外触发完整流程

---

## 完整示例

```yaml
---
name: code-review
description: "对当前分支的代码变更执行全面审查（安全、质量、性能）。当用户提出代码审查请求时使用。"
disable-model-invocation: true
allowed-tools: [Read, Grep, Glob, Bash(git diff*)]
model: opus
version: "1.0.0"
---

# /code-review — 代码审查

## 步骤

1. 运行 `git diff HEAD~1` 获取变更列表
2. 逐文件审查：安全漏洞、代码质量、性能问题
3. 按 CRITICAL/HIGH/MEDIUM/LOW 分级输出问题清单
4. 给出具体修复建议
```

---

## 触发机制

- **用户触发**：输入 `/skill-name`
- **Claude 自动触发**：根据 `description` 内容判断当前任务是否匹配，自动调用
- **禁止自动触发**：设置 `disable-model-invocation: true` 后，只能用 `/命令` 触发

---

## 命名规则

- 全小写，只允许字母、数字、连字符
- 最长 64 字符
- 文件/目录名必须与 `name` 字段一致
- ✅ `new-feature`、`bug-fix`、`code-review-v2`
- ❌ `NewFeature`、`new_feature`、`new feature`
