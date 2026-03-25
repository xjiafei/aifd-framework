---
name: init-project
description: "当需要将 AIFD 框架接入一个新项目或已有项目时使用。引导完成项目定制区配置、架构文档初始化、Agent 模板选择、hook 路径配置等接入工作。"
---

# /init-project — 项目初始化向导

> 将 AIFD 框架接入你的项目。绿地（新建）和存量（已有代码）项目均适用。

---

## 执行流程

### 阶段一：信息收集

使用 `AskUserQuestion` 逐步收集项目信息：

**问题 1：项目基本信息**
- 项目名称（英文，用于目录命名）
- 项目类型：
  - A. 后端 API 服务（RESTful / GraphQL）
  - B. 前端 SPA / Web 应用
  - C. 全栈项目（前后端在同一仓库）
  - D. 微服务（多仓库编排）
  - E. 其他（说明）

**问题 2：技术栈**
- 后端语言与框架（如：Java + Spring Boot 3.x、Python + FastAPI、Go + Gin、Node.js + Express）
- 前端框架（如：Vue 3、React 18、无前端）
- 数据库（如：MySQL 8、PostgreSQL、MongoDB、无数据库）
- 构建工具（如：Maven、Gradle、npm、pnpm、go build）

**问题 3：代码仓库**
- 代码根目录路径（相对于本框架目录，如：../my-app 或绝对路径）
- 是否有多个子仓库？若有，列出仓库名称和路径

**问题 4：项目现状**
- 是否是全新项目（绿地）？
- 还是已有代码（存量）？若是存量，现有代码大概几个模块？

**问题 5：代码路径模式**（hook 守卫配置）
- 代码文件主要在哪些目录？（默认：src/ backend/ frontend/）
- 是否有特殊路径？（如 Go 项目的 cmd/ internal/ pkg/）

---

### 阶段二：生成配置

#### 2.1 填写 CLAUDE.md 项目定制区

读取 `CLAUDE.md`，更新 `## 8. 项目定制区` 的三张表：

**技术栈表**（按实际信息填写）：
```markdown
| 层级 | 技术选型 | 版本 |
|------|----------|------|
| 语言 | {语言} | {版本} |
| 框架 | {框架} | {版本} |
| 数据库 | {数据库} | {版本} |
| 构建工具 | {工具} | {版本} |
```

**代码仓库路径表**：
```markdown
| 仓库 | 路径 | 说明 |
|------|------|------|
| {仓库名} | {路径} | {说明} |
```

**构建验证命令表**：
```markdown
| 检查项 | 命令 | 通过标准 |
|--------|------|----------|
| Lint | {命令} | 零错误 |
| 单元测试 | {命令} | 全部通过 |
| 构建 | {命令} | 成功退出 |
```

#### 2.2 更新 Hook 路径配置

根据问题 5 的回答，更新 `.claude/hooks/check-coding-gate.sh` 中的 `is_code_path()` 函数：

```bash
is_code_path() {
  case "$1" in
    # 填入项目实际代码路径模式
    {路径1}/*|{路径2}/*)
      return 0 ;;
    *)
      return 1 ;;
  esac
}
```

#### 2.3 配置技术栈 Agent

不需要复制模板文件。直接在 `.claude/agents/dev-agent.md` 的 `<!-- DYNAMIC_INJECT_START -->` 区域写入项目技术约束：

使用 `Edit` 工具，将 `dev-agent.md` 中的注入区替换为以下内容（根据实际技术栈填写）：

```markdown
<!-- DYNAMIC_INJECT_START -->
## 当前项目技术约束

- **技术栈**：{语言 + 框架，例如：Java 17 + Spring Boot 3.2}
- **构建命令**：{例如：mvn clean package -DskipTests}
- **测试命令**：{例如：mvn test}
- **代码规范**：参见 docs/knowledges/standards/（如存在）
- **架构规范**：参见 docs/architecture.md
- **代码路径**：{主要源码目录，例如：src/main/java/}
<!-- DYNAMIC_INJECT_END -->
```

同步在 `.claude/agents/qa-agent.md`、`arch-agent.md` 的注入区填入：

```markdown
<!-- DYNAMIC_INJECT_START -->
## 当前项目上下文

- **技术栈**：{技术栈}
- **测试框架**：{例如：JUnit 5 + Mockito / pytest / Vitest}
- **测试命令**：{测试命令}
- **代码路径**：{源码目录}
<!-- DYNAMIC_INJECT_END -->
```

**多技术栈项目（如 FE + BE 分离）**：在对应 agent 的注入区分别填写各自技术栈信息；或为 FE/BE 各创建专用 agent 文件（如 `fe-dev-agent.md` / `be-dev-agent.md`），在 CLAUDE.md 的编排者说明中注记何时调用哪个。

#### 2.4 创建 docs/architecture.md

从 `docs/architecture.md`（当前为通用模板）创建项目专属版本：

- 填写技术栈表（语言、框架、数据库）
- 填写分层对应表（根据技术栈映射到4个架构原则层）
- 留空模块表和 API 汇总表（由后续功能开发填充）

#### 2.5 初始化 workspace/stage-status.json

创建初始状态文件：

```json
{
  "features": {},
  "lastUpdated": "{ISO timestamp}",
  "projectName": "{项目名称}"
}
```

---

### 阶段三：存量项目特殊处理

如果是存量项目（已有代码），额外执行：

#### 3.1 现状梳理

使用 `Glob` 和 `Read` 扫描现有代码结构，生成"现状报告"：
- 主要模块列表
- 识别到的技术债（不符合分层原则的代码）
- 建议的渐进迁移优先级

#### 3.2 创建基础架构知识

在 `docs/knowledges/architecture/` 创建 `001-initial-state.md`，记录：
- 当前系统的主要模块和职责
- 已知的技术债和约束
- 迁移计划的大方向

#### 3.2.5 配置 Hook 豁免路径（存量项目必须执行）

存量项目中大量遗留代码没有对应的 stage-status 记录，直接修改这些代码会被 hook 拦截。
在 `workspace/stage-status.json` 中添加 `legacyPaths` 字段，标记不受门禁约束的遗留路径：

```json
{
  "features": {},
  "projectName": "{项目名称}",
  "lastUpdated": "{ISO timestamp}",
  "legacyPaths": [
    "legacy/",
    "vendor/",
    "migrations/",
    "{其他遗留代码目录}/"
  ]
}
```

**原则**：只将真正不需要走流程的"遗留/第三方/迁移脚本"路径加入豁免。核心业务代码不得豁免。

#### 3.3 为核心模块创建最小化文档

对已有的 2-3 个核心模块，创建简化版的 `tech.md`（只记录接口定义，不走完整 P1-P3 流程）。
这为后续功能开发提供"追溯起点"。

---

### 阶段四：验证配置

#### 4.1 验证 Hook

通过尝试编辑一个代码文件，验证 hook 是否正确拦截：
```
预期结果：BLOCKED: 当前没有处于 implementation/running 状态的功能
```
如果 hook 未拦截，检查 check-coding-gate.sh 的路径模式配置。

#### 4.2 输出初始化报告

```markdown
## 项目初始化完成

**项目名称**: {项目名称}
**技术栈**: {技术栈}
**项目类型**: {类型}

### 已完成的配置
- ✅ CLAUDE.md 项目定制区已填写
- ✅ Hook 路径已配置（守护路径：{路径列表}）
- ✅ 技术栈 Agent 已配置
- ✅ docs/architecture.md 已创建
- ✅ workspace/stage-status.json 已初始化
{如果是存量项目:}
- ✅ 现状梳理报告已生成
- ✅ 初始架构知识已录入

### 下一步
1. 检查 docs/architecture.md 中的分层映射是否符合项目实际情况
2. 运行 /new-feature 开始第一个功能的开发
3. 如需进一步了解框架使用方法，参阅 workflows/full-lifecycle.md
```

---

## 注意事项

- 初始化过程**不会修改**你的业务代码，只配置框架文件
- 如果初始化中断，可以重新运行 `/init-project`（会询问是否覆盖已有配置）
- 存量项目的渐进迁移不需要一次完成，框架与现有代码可以共存
