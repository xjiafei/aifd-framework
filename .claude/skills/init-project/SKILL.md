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
  ├── aifd-framework/        ← 框架实例（Claude Code 工作目录）
  ├── backend/               ← 后端类别目录（非 git 仓库，仅用于分组）
  │   ├── auth-service/      ← 独立 git 仓库（clone 目标）
  │   ├── user-service/      ← 独立 git 仓库（clone 目标）
  │   └── order-service/     ← 独立 git 仓库（clone 目标）
  ├── frontend/              ← 前端类别目录（非 git 仓库，仅用于分组）
  │   ├── web-app/           ← 独立 git 仓库（clone 目标）
  │   └── admin-panel/       ← 独立 git 仓库（clone 目标）
  ├── testing/               ← 测试脚本
  │   └── e2e/               ← E2E Playwright 脚本
  └── ...
```

> 框架内的相对路径均以 `..` 开头引用同级目录（如 `../backend/auth-service`）。
> **每个仓库目录是独立的 git 仓库**；类别目录（backend/frontend）本身不是 git 仓库，只起分组作用。

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

**问题 2：项目现状**（提前询问，决定后续收集方式）
- 是否是全新项目（绿地）？
- 还是已有代码（棕地/存量）？若是存量，现有代码大概几个模块？

> 棕地项目的技术栈将在代码克隆/扫描后自动检测，无需手动填写。

**问题 3：代码仓库**

首先询问：是否有远程仓库需要克隆到本地？

**场景 A：有远程仓库需要克隆（棕地接入）**

按分组收集仓库信息。每个分组对应一个类别目录（如 backend / frontend），每个仓库克隆到该类别目录下的独立子目录。

示例表格（用户填写）：

| 类别目录 | 仓库目录名 | 远程 URL | 主分支 |
|----------|-----------|----------|--------|
| backend | auth-service | https://github.com/org/auth.git | main |
| backend | user-service | git@github.com:org/user.git | main |
| frontend | web-app | https://github.com/org/web.git | master |
| frontend | admin-panel | https://github.com/org/admin.git | main |

克隆后目录结构：
```
../backend/auth-service/
../backend/user-service/
../frontend/web-app/
../frontend/admin-panel/
```

**场景 B：代码已在本地**

- 提供各仓库的本地路径（相对于本框架目录，如：../backend/auth-service）
- 每个仓库的主分支名称（默认：main）

**问题 4：技术栈**（**仅绿地项目**询问，棕地跳过）
- 后端语言与框架（如：Java + Spring Boot 3.x、Python + FastAPI、Go + Gin、Node.js + Express）
- 前端框架（如：Vue 3、React 18、无前端）
- 数据库（如：MySQL 8、PostgreSQL、MongoDB、无数据库）
- 构建工具（如：Maven、Gradle、npm、pnpm、go build）

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

#### 0. 克隆远程仓库（场景 A 专属，场景 B 跳过）

仅当用户在问题 3 选择"有远程仓库需要克隆"时执行此步骤。

对问题 3 收集到的每条仓库记录，按顺序执行：

1. **确定目标路径**：`{项目根目录}/{类别目录}/{仓库目录名}`，相对于框架目录为 `../{类别目录}/{仓库目录名}`

2. **检查目标目录是否已存在**：
   - 若目录已存在且**非空**：询问用户选择
     - `[S] 跳过`：保留现有代码，直接记录路径
     - `[R] 重新克隆`：删除目录后重新克隆（需用户确认）
   - 若目录不存在或为空：继续执行克隆

3. **创建类别目录**（如不存在）：
   ```bash
   mkdir -p ../{类别目录}
   ```

4. **克隆仓库**：
   ```bash
   git clone {远程URL} ../{类别目录}/{仓库目录名}
   ```
   - 若 URL 为 SSH 格式（`git@...`），提示用户确保 SSH key 已配置
   - 若克隆失败（网络/权限），记录错误，继续处理其余仓库，最终在报告中列出失败项

5. **克隆成功后检测实际主分支**：
   ```bash
   git -C ../{类别目录}/{仓库目录名} symbolic-ref --short HEAD
   ```
   以实际检测结果为准（覆盖用户填写的值）

6. **将该仓库记录到内部列表**，供后续 §2.1 填写 CLAUDE.md 使用：
   ```
   仓库名: {仓库目录名}
   路径: ../{类别目录}/{仓库目录名}
   主分支: {检测结果}
   说明: {类别目录}
   ```

所有仓库处理完毕后，在阶段四的初始化报告中汇总克隆结果（成功/跳过/失败）。

---

#### 0.5 技术栈自动检测（棕地项目专属，绿地跳过）

**触发时机**：
- 场景 A：§0 克隆完成后立即执行
- 场景 B（本地已有代码）：§2.0 执行前执行

对内部仓库列表中的每个仓库路径，使用 `Glob` 扫描根目录及一级子目录的特征文件，按以下规则推断技术栈：

**语言/框架检测规则**：

| 特征文件 | 推断结论 |
|---------|---------|
| `pom.xml` | Java + Maven |
| `build.gradle` / `build.gradle.kts` | Java 或 Kotlin + Gradle |
| `go.mod` | Go（读取文件内容，从 `require` 块推断框架：gin / echo / fiber / chi） |
| `requirements.txt` / `pyproject.toml` / `setup.py` | Python（读取内容推断框架：fastapi / django / flask） |
| `Cargo.toml` | Rust |
| `composer.json` | PHP |
| `package.json` | Node.js（读取 `dependencies` 字段推断细分）：<br>- 含 `"react"` → React<br>- 含 `"vue"` → Vue<br>- 含 `"next"` → Next.js<br>- 含 `"nuxt"` → Nuxt<br>- 含 `"@nestjs/core"` → NestJS<br>- 含 `"express"` → Express<br>- 无前端框架特征 → Node.js（通用） |

**数据库检测规则**（读取以下配置文件内容，查找关键词）：

| 配置文件 | 关键词 → 数据库 |
|---------|--------------|
| `src/main/resources/application.properties` 或 `application.yml` | `mysql` → MySQL；`postgresql` / `postgres` → PostgreSQL；`h2` → H2（测试库） |
| `requirements.txt` / `pyproject.toml` | `pymongo` → MongoDB；`psycopg2` / `asyncpg` → PostgreSQL；`mysql-connector` / `aiomysql` → MySQL；`sqlalchemy` → 关系型（需进一步看 DB URL） |
| `package.json` | `mongoose` → MongoDB；`pg` / `@prisma/client`（Prisma schema 中找 provider）→ PostgreSQL；`mysql2` / `knex` → MySQL |
| `go.mod` | `gorm.io/driver/mysql` → MySQL；`gorm.io/driver/postgres` → PostgreSQL；`go.mongodb.org/mongo-driver` → MongoDB |

**检测完成后**：

1. 汇总所有仓库结果，以表格形式展示给用户确认：

   ```
   检测到以下技术栈（请确认，如有误可直接修正）：

   | 仓库 | 语言/框架 | 数据库 | 构建工具 |
   |------|----------|--------|---------|
   | backend/auth-service | Java 17 + Spring Boot 3.x | MySQL | Maven |
   | backend/user-service | Java 17 + Spring Boot 3.x | PostgreSQL | Maven |
   | frontend/web-app | Node.js + Vue 3 | 无 | npm |
   | frontend/admin-panel | Node.js + React | 无 | pnpm |
   ```

2. 用户确认或修正后，将最终结果记录为内部"技术栈上下文"，格式：
   ```
   仓库: backend/auth-service
   语言框架: Java 17 + Spring Boot 3.x
   数据库: MySQL
   构建工具: Maven
   ```

3. 此上下文用于后续 §2.1 填写 CLAUDE.md 技术栈表，以及 §2.3 配置 Agent 注入区。
   - 多仓库多技术栈时，§2.1 的技术栈表按仓库分组填写（或合并相同栈）
   - §2.3 的 agent 注入区按仓库分别填写各自的语言/构建/测试信息

---

#### 2.0 初始化 Git 仓库

**仓库列表来源**：
- 场景 A（远程克隆）：使用步骤 §0 构建的内部列表（已克隆的全部路径）
- 场景 B（本地已有，棕地）：使用问题 3 用户填写的本地路径列表；执行本步骤前先完成 §0.5 技术栈检测
- 场景 B（本地已有，绿地）：使用问题 3 用户填写的本地路径列表；技术栈来自问题 4 的用户填写

对列表中的每个代码仓库路径：

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

> **后续维护**：当项目新增仓库或技术栈时（如新增 Python 微服务），需同步更新：
> 1. CLAUDE.md §8 仓库路径表和技术栈表
> 2. 相关 agent 文件的 DYNAMIC_INJECT 注入区
> 编排者在新功能启动时应检查注入区与 CLAUDE.md §8 是否一致，不一致则先更新。

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
