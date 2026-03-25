# Hooks 完整规格

## 配置位置

```
.claude/settings.json          ← 项目级，可提交到 git
.claude/settings.local.json    ← 项目本地，不提交
~/.claude/settings.json        ← 全局级，所有项目生效
~/.claude/settings.local.json  ← 全局本地，不提交
```

---

## JSON 格式（两种写法均支持）

### 简洁格式（当前项目使用）
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

### 嵌套格式（官方推荐，更灵活）
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/validate-bash.sh",
            "timeout": 5000,
            "statusMessage": "验证命令安全性..."
          }
        ]
      }
    ]
  }
}
```

---

## 支持的事件类型

| 事件 | 触发时机 | 可阻止 | 典型用途 |
|------|---------|--------|---------|
| `PreToolUse` | 工具执行前 | **是（exit 2）** | 阻止危险操作、强制前置检查 |
| `PostToolUse` | 工具成功后 | 否 | 自动格式化、运行测试 |
| `PostToolUseFailure` | 工具失败后 | 否 | 记录错误、触发恢复 |
| `UserPromptSubmit` | 用户发送消息时 | **是（exit 2）** | 输入验证、注入上下文 |
| `SessionStart` | 会话启动时 | 否 | 初始化环境、加载配置 |
| `Stop` | Claude 完成响应时 | 否 | 最终验证、构建检查、通知 |
| `SubagentStop` | 子代理完成时 | 否 | 监控子代理结果 |
| `Notification` | 发送通知时 | 否 | 自定义通知渠道 |
| `PreCompact` | 上下文压缩前 | 否 | 保存关键信息 |

---

## 退出码（关键！）

| 退出码 | 含义 | 适用事件 |
|--------|------|---------|
| `0` | 成功，正常继续 | 所有 |
| **`2`** | **拒绝，终止工具调用** | PreToolUse、UserPromptSubmit |
| 其他 | 非阻塞错误，仅记录日志 | 所有 |

> **常见错误**：`exit 1` 不会拒绝操作，只会记录错误日志。**必须用 `exit 2` 才能真正阻止。**

---

## matcher 格式

```
"*"                    # 匹配所有工具
"Bash"                 # 匹配特定工具
"Edit|Write"           # 匹配多个工具（OR）
"Bash(git *)"          # 匹配工具+参数模式
"Write(*.env)"         # 匹配特定文件类型的写入
"Write(src/**)"        # 匹配特定目录的写入
"Bash(rm *|rmdir *)"   # 多个参数模式
```

---

## 环境变量（hook 脚本可用）

| 变量 | 说明 |
|------|------|
| `$CLAUDE_TOOL_INPUT` | 工具完整 JSON 输入 |
| `$CLAUDE_TOOL_INPUT_FILE_PATH` | 被编辑文件的路径 |
| `$CLAUDE_TOOL_NAME` | 被调用工具名称 |
| `$CLAUDE_TOOL_ARGUMENTS` | 工具参数（JSON） |
| `$CLAUDE_PROJECT_DIR` | 项目根目录 |

---

## Hook 输出格式（可选，通过 stdout 返回 JSON）

```json
{
  "continue": true,
  "decision": "approve|deny|modify",
  "reason": "向用户展示的原因",
  "additionalContext": "注入给 Claude 的额外上下文",
  "modifiedInput": { /* 修改后的工具输入 */ },
  "message": "状态消息"
}
```

---

## 实用示例

### 示例1：强制执行计划（当前项目已用）
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash -c 'FILE=\"$CLAUDE_TOOL_INPUT_FILE_PATH\"; case \"$FILE\" in src/*|lib/*) if [ -z \"$(ls docs/plans/active/ 2>/dev/null | grep -v .gitkeep)\" ]; then echo \"BLOCKED: 请先创建执行计划\" >&2; exit 2; fi;; esac; exit 0'"
      }
    ]
  }
}
```

### 示例2：保护敏感文件
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write(.env*)|Read(.env*)",
        "command": "bash -c 'echo \"BLOCKED: 禁止读写 .env 文件\" >&2; exit 2'"
      }
    ]
  }
}
```

### 示例3：代码提交后自动格式化
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true",
            "timeout": 10000,
            "statusMessage": "自动格式化..."
          }
        ]
      }
    ]
  }
}
```

### 示例4：响应结束后运行测试
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "command": "bash -c 'cd \"$CLAUDE_PROJECT_DIR\" && npm test --silent 2>&1 | tail -5'"
      }
    ]
  }
}
```

### 示例5：阻止危险 Bash 命令
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "bash -c 'echo \"$CLAUDE_TOOL_INPUT\" | python3 -c \"import sys,json; cmd=json.load(sys.stdin).get(\\\"command\\\",\\\"\\\"); exit(2 if any(x in cmd for x in [\\\"rm -rf /\\\",\\\"DROP TABLE\\\",\\\"--force\\\"]) else 0)\"'"
      }
    ]
  }
}
```

---

## 调试技巧

- 用 `Ctrl+O` 查看 verbose 模式下的 hook 日志
- hook 脚本的 stderr 会显示给用户（用于展示错误原因）
- hook 脚本的 stdout JSON 会被 Claude 读取（用于注入上下文）
- 测试 hook：`echo '{"file_path":"src/test.ts"}' | bash -c 'your-hook-command'`
