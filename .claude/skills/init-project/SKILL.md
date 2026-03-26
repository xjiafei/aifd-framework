---
name: init-project
description: "当需要将 AIFD 框架接入一个新项目或已有项目时使用。引导完成项目定制区配置、架构文档初始化、Agent 模板选择、hook 路径配置等接入工作。"
---

# /init-project — 项目初始化向导

> 将 AIFD 框架接入你的项目。绿地（新建）和存量（已有代码）项目均适用。

### 推荐目录结构

aifd-framework 应放在项目根目录内，与业务代码目录同级：

```
{project-root}/
  ├── aifd-framework/    ← 框架实例（Claude Code 工作目录）
  ├── backend/           ← 后端代码（可以是独立 git 仓库）
  ├── frontend/          ← 前端代码（可以是独立 git 仓库）
  ├── testing/           ← 测试脚本
  │   └── e2e/           ← E2E Playwright 脚本
  └── ...
```

> 框架内的相对路径均以 `..` 开头引用同级目录（如 `../backend`、`../frontend`）。
> 每个子目录可以是独立的 git 仓库，也可以统一使用项目根目录的 git 仓库。

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
- 每个仓库的主分支名称？（默认：main。常见选项：main / master / develop）

**问题 4：项目现状**
- 是否是全新项目（绿地）？
- 还是已有代码（存量）？若是存量，现有代码大概几个模块？

**问题 5：代码路径模式**（hook 守卫配置）
- 代码文件主要在哪些目录？（默认：src/ backend/ frontend/）
- 是否有特殊路径？（如 Go 项目的 cmd/ internal/ pkg/）

**问题 6：E2E 测试配置**（仅全栈或前端项目）
- 前端开发服务器启动命令？（如：`npm run dev`）
- 前端地址？（如：`http://localhost:5173`）
- 后端启动命令？（如：`mvn spring-boot:run` / `npm run dev:server`）
- 后端健康检查 URL？（如：`http://localhost:8080/actuator/health`）
- 是否已安装 Playwright？（如未安装，初始化时会提示安装步骤）

---

### 阶段二：生成配置

#### 2.0 初始化 Git 仓库

对阶段一中声明的每个代码仓库路径：

1. 检查该目录是否存在 `.git` 目录
2. 如果**没有** git 仓库：
   - `cd {代码仓库路径}`
   - `git init`
   - 根据技术栈生成 `.gitignore`（Java: `target/`, `*.class`, `.idea/`; Node: `node_modules/`, `dist/`; Python: `__pycache__/`, `.venv/`; Go: `vendor/`）
   - `git add . && git commit -m "Initial project structure"`
   - 记录主分支名称为 `main`（新仓库默认）
3. 如果已有 git 仓库：
   - 用 `git symbolic-ref --short HEAD` 检测当前默认分支名称
   - 跳过初始化，记录到报告

同时检查框架实例目录（当前工作目录）：
1. 检查是否有 `.git` 目录
2. 如果没有：`git init && git add . && git commit -m "AIFD framework initialized"`
3. 如果已有：跳过

在阶段四的初始化报告中记录 git 初始化状态。

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
| 仓库 | 路径 | 主分支 | 说明 |
|------|------|--------|------|
| {仓库名} | {路径} | {主分支，默认 main} | {说明} |
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

#### 2.6 清理 workspace 模板

- 确认 `workspace/cr-index.md` 索引表为空（无残留示例数据）
- 确认 `workspace/memory.md` 区域 A-E 内容为项目初始模板状态

#### 2.7 初始化 E2E 测试基础设施（全栈/前端项目）

如果项目类型为 B（前端）或 C（全栈）：

1. 检查代码仓库中是否存在 `playwright.config.ts` 或 `testing/e2e/playwright.config.ts`
2. 如果不存在，生成基础 Playwright 配置文件 `testing/e2e/playwright.config.ts`：
   ```typescript
   import { defineConfig } from '@playwright/test';

   export default defineConfig({
     testDir: '.',
     use: {
       baseURL: '{frontend_url}',
       headless: true,
       screenshot: 'only-on-failure',
     },
     projects: [
       { name: 'chromium', use: { browserName: 'chromium' } },
     ],
     reporter: [['json', { outputFile: 'test-results.json' }]],
   });
   ```
3. 创建 `testing/e2e/` 目录（如不存在）
4. 在初始化报告中记录 E2E 基础设施状态
5. 提示用户：如需运行 E2E 测试，需先执行 `npx playwright install chromium`

#### 2.8 多仓库分支信息采集

对阶段一中声明的每个代码仓库：

1. `cd {仓库路径}`
2. 检测当前默认分支：`git symbolic-ref --short HEAD`（新 init 的仓库默认为 `main`）
3. 将检测到的主分支名填入 CLAUDE.md §8 代码仓库路径表的"主分支"列
4. 在初始化报告中记录各仓库的分支信息

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
