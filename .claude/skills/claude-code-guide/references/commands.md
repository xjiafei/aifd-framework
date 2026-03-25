# Slash Commands 完整规格

## 说明

Commands 和 Skills 本质相同，格式完全一致。区别在于：

| | Commands | Skills |
|-|---------|--------|
| 存放位置 | `.claude/commands/` | `.claude/skills/` |
| 文件夹格式主文件 | 任意名称.md | 必须命名 `SKILL.md` |
| 系统处理 | 完全相同 | 完全相同 |

---

## 文件位置

```
.claude/commands/command-name.md     ← 项目级（可提交）
~/.claude/commands/command-name.md   ← 全局级（所有项目）
```

---

## Frontmatter 字段（同 Skills）

```yaml
---
name: command-name                    # 必填：≤64字符，小写+连字符
description: "做什么 + 何时用"        # 推荐：显示在 /help 中（≤1024字符）
argument-hint: "[branch-name]"        # 可选：自动补全提示
allowed-tools: [Bash(git *), Read]    # 可选：工具白名单
model: sonnet                         # 可选：模型覆盖
disable-model-invocation: false       # 可选：仅手动触发
---
```

---

## 参数传递

Commands 可以接受用户输入的参数：

```
/deploy production
/review-pr 123
/fix-bug AUTH-001
```

在 command 正文中用 `$ARGUMENTS` 或描述性占位符引用：

```markdown
---
name: deploy
description: "部署到指定环境"
argument-hint: "[environment]"
---

# /deploy

将当前分支部署到 $ARGUMENTS 环境。

步骤：
1. 确认目标环境：$ARGUMENTS
2. 运行构建命令
3. 执行部署脚本
```

---

## 完整示例

```yaml
---
name: git-commit
description: "创建规范化的 git commit，自动生成 commit message。当需要提交代码时使用。"
disable-model-invocation: true
allowed-tools: [Bash(git *), Read]
model: haiku
argument-hint: "[scope]"
---

# /git-commit

创建符合 Conventional Commits 规范的提交。

## 步骤

1. 运行 `git status` 查看变更
2. 运行 `git diff --staged` 查看已暂存内容
3. 根据变更内容生成 commit message：
   - feat: 新功能
   - fix: 修复 bug
   - refactor: 重构
   - docs: 文档更新
   - test: 测试相关
4. 运行 `git commit -m "type(scope): message"`
5. 确认提交成功
```

---

## 与 Skills 的选择建议

- **放 commands/**：简单的一次性操作（commit、format、deploy）
- **放 skills/**：复杂的多步骤流程（new-feature、bug-fix、close-loop）
- **实际上两者无技术差别**，按团队习惯组织即可
