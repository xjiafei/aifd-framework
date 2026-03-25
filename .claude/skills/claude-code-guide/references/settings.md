# Settings 完整规格

## 文件位置与优先级

优先级从高到低（高优先级覆盖低优先级）：

```
1. .claude/settings.local.json      ← 项目本地覆盖（不提交 git）
2. .claude/settings.json            ← 项目共享设置（可提交 git）
3. ~/.claude/settings.local.json    ← 全局本地覆盖（不提交）
4. ~/.claude/settings.json          ← 全局设置
```

---

## 完整 JSON 结构

```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(npm run *)",
      "Read(*.md)",
      "Edit",
      "Write(docs/**)"
    ],
    "ask": [
      "Bash(git push*)",
      "Write(.env*)",
      "Delete"
    ],
    "deny": [
      "Read(.env*)",
      "Bash(rm -rf*)",
      "Bash(curl*)"
    ]
  },

  "env": {
    "NODE_ENV": "development",
    "DEBUG": "false",
    "API_KEY": "${CUSTOM_API_KEY}"
  },

  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash -c 'your-validation-script'"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\"",
            "timeout": 10000,
            "statusMessage": "格式化代码..."
          }
        ]
      }
    ]
  },

  "model": "claude-sonnet-4-6",
  "alwaysThinkingEnabled": false,
  "autoMemoryEnabled": true,
  "skipDangerousModePermissionPrompt": false,

  "statusLine": {
    "show": true,
    "format": "{model} | {tokens} | {stop_reason}"
  },

  "mcp": {
    "servers": {
      "server-name": {
        "command": "node",
        "args": ["path/to/server.js"],
        "env": {
          "API_KEY": "${API_KEY}"
        }
      }
    }
  }
}
```

---

## permissions 规则

### 格式
```
"ToolName"                  # 匹配该工具的所有调用
"ToolName(pattern)"         # 匹配带特定参数的调用
"ToolA|ToolB"              # 匹配多个工具
"Write(src/**)"             # 匹配特定路径模式
"Bash(git *)"               # 匹配特定命令前缀
```

### 评估规则
1. 先检查 `deny` — 第一个匹配即拒绝
2. 再检查 `allow` — 第一个匹配即允许（无需确认）
3. 再检查 `ask` — 第一个匹配即询问用户
4. 无匹配 — 询问用户（默认行为）

### 常用权限配置示例
```json
{
  "permissions": {
    "allow": [
      "Read",
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(npm run lint)",
      "Bash(npm run test)"
    ],
    "ask": [
      "Bash(git commit*)",
      "Bash(git push*)",
      "Write",
      "Edit"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(rm -rf*)",
      "Read(.env*)"
    ]
  }
}
```

---

## env 环境变量

```json
{
  "env": {
    "NODE_ENV": "development",
    "DEBUG": "true",
    "API_BASE_URL": "https://api.example.com",
    "API_KEY": "${MY_API_KEY}"
  }
}
```

- 可以用 `${VAR_NAME}` 引用 shell 环境变量
- 项目 settings.json 中的 env 会在 Claude 执行工具时注入

---

## 重要注意事项

1. **deny 权限可能不对 Read/Write 生效**：官方文档有记录此问题，用 hooks 作为兜底方案更可靠。

2. **settings.local.json 不提交**：包含个人配置、本地路径等，应加入 `.gitignore`。

3. **hooks 配置在 settings.json 中**：不在独立文件，详见 `references/hooks.md`。

4. **权限立即生效**：修改 settings.json 后无需重启，下次工具调用时生效。
