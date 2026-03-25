# CLAUDE.md 与 Memory 完整规格

## CLAUDE.md

### 文件位置与加载规则

```
CLAUDE.md                        ← 项目根目录，会话启动时立即加载
src/CLAUDE.md                    ← 子目录，当 Claude 读取 src/ 下文件时懒加载
~/.claude/CLAUDE.md              ← 全局，所有会话生效
.claude/rules/*.md               ← 路径作用域规则（需在 frontmatter 指定 paths）
```

**加载特性：**
- 根目录 `CLAUDE.md` 在会话启动时自动读入系统提示
- 子目录 `CLAUDE.md` 是**懒加载**——只有 Claude 访问该目录文件时才加载
- 所有匹配的 CLAUDE.md 内容合并进上下文
- 全局 `~/.claude/CLAUDE.md` 对所有项目生效

---

### 路径作用域规则（.claude/rules/）

```markdown
---
paths: ["**/*.tsx", "**/*.ts", "src/**"]
---

# React/TypeScript 规范

处理 TypeScript 文件时：
- 使用函数式组件 + Hooks
- 开启 TypeScript 严格模式
- 优先 interface 而非 type
```

**触发机制**：当 Claude 读取匹配 `paths` 的文件时，对应规则文件自动加载。

---

### 最佳实践

| 做 | 不做 |
|----|------|
| 只写项目特定指令 | 不写通用建议（"写干净的代码"浪费 token）|
| 保持在 200 行以内 | 不超过 200 行（超出部分截断）|
| 关键规则用 hooks 兜底 | 不只靠文本指令（上下文压缩后可能丢失）|
| 用 `@import` 引用长文档 | 不把所有内容塞进一个文件 |
| 子目录按需拆分 | 不在根 CLAUDE.md 写所有规则 |

---

### 优先级（从高到低）

1. 用户在对话中的显式指令
2. CLAUDE.md + Skills 指令
3. 系统默认提示

---

### 推荐结构

```markdown
# 项目名称

## 架构概览
[1-3 句话描述项目结构]

## 关键路径
- src/: 源代码
- docs/: 文档
- tests/: 测试

## 编码规范
[只写本项目特定的规范]

## 常用命令
- 构建：`npm run build`
- 测试：`npm test`

## 禁止事项
- 不直接操作数据库，通过 Repository 层
- 不在 Controller 层写业务逻辑
```

---

## Memory（自动记忆）

### 文件位置

```
~/.claude/projects/<project-hash>/memory/MEMORY.md
```

Claude Code 自动管理，路径基于 git 项目派生。

---

### CLAUDE.md vs MEMORY.md

| | CLAUDE.md | MEMORY.md |
|-|-----------|-----------|
| 谁写 | 开发者手动写 | Claude 自动写 |
| 内容 | 项目规范、架构约束、指令 | Claude 学到的经验、调试洞察 |
| 更新 | 手动更新 | 跨会话自动积累 |
| 版本控制 | 提交到 git | 不提交（个人数据）|
| 持久性 | 永久（除非手动删除）| 随时间积累 |

---

### Memory 存储内容

Claude 会自动记录：
- 构建命令和测试命令
- 调试过的已知问题和解决方案
- 架构决策和模式
- 代码风格偏好
- 工作流习惯

---

### 手动记忆文件（本项目模式）

本项目使用 `workspace/memory.md` 作为显式项目记忆文件，由编排者手动维护：

```markdown
# 项目记忆

## 架构决策
- [2024-01] 选择 PostgreSQL 而非 MongoDB — 理由：事务需求强

## 已知问题
- 端口 3000 被占用 — 用 `lsof -i :3000 | kill $(awk '{print $2}')` 解决

## 经验教训
- P3 阶段必须包含详细的 API 接口定义，否则 dev-agent 会自己发明接口
```

这与 `MEMORY.md` 的区别是：`workspace/memory.md` 是**主动记录的团队知识**，可提交到 git。
