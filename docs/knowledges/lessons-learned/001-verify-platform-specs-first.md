# L-001: 先查平台官方规格，再设计框架

## 事件

AIFD 框架 v1-v9 的 agents 和 skills 定义全部不符合 Claude Code 官方标准：
- agents 放在根目录 `agents/` 而非官方要求的 `.claude/agents/`
- frontmatter 用 `tools` 而非官方的 `allowed-tools`
- 没有 `model` 字段（官方支持按 agent 指定模型）
- skills 没有 YAML frontmatter（官方要求 `name` + `description` 必填）

## 根因

设计时基于三个非权威来源推断平台行为，从未查阅 Claude Code 官方文档：
1. 参考文章（OpenAI Harness Engineering + 代码熵管理）— 理论层，不涉及 Claude Code API
2. enbrands-media2 实践 — 该项目本身也不符合官方标准
3. 设计者对 Claude Code 的假设 — "Claude Code 是单 Agent 架构，agents/ 只是 prompt 模板"（错误）

## 后果

- agents 无法被 Claude Code 原生发现和调度
- model 字段无法生效，无法实现模型路由
- skills 无法被 Claude Code 自动触发
- 在 CLAUDE.md 中额外写了"模型路由建议"来弥补——而原生 frontmatter 就能解决

## 教训

**在设计任何基于平台的框架时，第一步必须查阅平台的官方规格文档。**

不要：
- 假设自己知道平台怎么工作
- 仅凭第三方项目推断官方标准
- 用"先做再说"绕过规格验证

要做：
- 查官方文档确认文件格式、字段名、目录结构
- 写一个最小样例验证平台行为
- 把验证结果记录到 memory.md

## 适用范围

此教训适用于所有基于特定平台/工具链的框架设计，不限于 Claude Code。
