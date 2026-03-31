---
name: brownfield-onboard
description: "当需要深入理解棕地（已有）项目、为其补充业务领域知识/编码规范/设计规范，并为核心功能生成规格文档时使用。触发词：/brownfield-onboard、理解项目、补充知识、知识化、梳理存量。"
---

# /brownfield-onboard — 棕地项目知识化

> 对已有代码库进行系统性分析，提取业务领域知识、编码规范、设计规范，并为核心功能补充规格文档。
> **前提**：项目已通过 `/init-project` 接入框架（已配置 CLAUDE.md §8 和 hook）。

---

## 执行流程

### 阶段一：项目扫描与模块识别

#### 1.1 读取已有配置

1. 读取 `CLAUDE.md §8 项目定制区`，获取：
   - 代码仓库路径列表
   - 技术栈信息
2. 读取 `docs/architecture.md`，了解已记录的架构信息
3. 读取 `docs/knowledges/index.md`，确认已有知识条目，避免重复

#### 1.2 代码库结构扫描

对每个代码仓库，使用 `Glob` 进行多轮扫描：

**第一轮：顶层结构**
```
{repo}/*                   → 识别顶层目录
{repo}/src/**/*.{ext}      → 识别源码文件数量和分布
```

**第二轮：关键入口点**
- 查找 main/index/app 等入口文件（main.go、main.py、Application.java、index.ts 等）
- 查找配置文件（application.yml、.env.example、config.py、settings.ts 等）
- 查找路由/控制器文件（Router、Controller、Handler、routes/ 等）

**第三轮：模型层扫描**
- 查找实体/模型定义（Entity、Model、Schema、domain/ 等）
- 查找数据库 migration 文件（识别表结构和演进历史）
- 查找 DTO/VO/Request/Response 定义

**第四轮：测试文件扫描**
- 查找测试目录（test/、spec/、__tests__/ 等）
- 粗估测试覆盖比例

#### 1.3 模块边界识别

读取关键目录结构，识别项目的主要业务模块：

1. 按 package/module/directory 组织方式，列出 **3~10 个核心业务模块**
2. 对每个模块，读取 1~3 个关键文件，理解其职责
3. 构建**模块职责地图**（模块名 + 单句职责描述）

用 `AskUserQuestion` 向用户确认：
> 「我识别到以下核心模块，请确认是否正确，并补充任何遗漏：
> {模块列表}
> 是否有你特别希望我重点分析的模块？」

---

### 阶段二：业务领域知识提取

> **目标**：将分散在代码中的业务语义提炼为结构化的领域知识。

#### 2.1 术语表提取

扫描以下位置，提取业务术语：
- 实体/模型的类名、字段名（去掉技术前缀如 `Base`、`Abstract`）
- 枚举类型的值（状态机枚举往往最能反映业务概念）
- 注释/文档字符串中的业务描述
- API 路径中的资源名称（`/orders`、`/users`、`/invoices`）
- 数据库表名

对每个识别出的核心业务术语，尝试从代码中推断其定义：
```
术语：Order（订单）
推断来源：entity/Order.java 字段 + OrderStatus 枚举 + OrderService 方法名
含义：用户对商品发起购买意向并确认的记录，包含商品列表、价格、配送信息
生命周期：PENDING → CONFIRMED → SHIPPED → DELIVERED / CANCELLED
```

**输出文件**：`docs/knowledges/domain/{domain}-glossary.md`

```markdown
## Meta
- **类型**：业务领域知识
- **适用场景**：编写需求/技术文档时，确保术语统一
- **关键词**：{提取的核心术语，逗号分隔}
- **创建时间**：{今天日期}
- **来源功能**：brownfield-onboard

---

# {领域名} 术语表

## 核心实体

| 术语（中文） | 术语（代码名） | 定义 | 生命周期/状态 |
|------------|-------------|------|-------------|
| 订单 | Order | ... | PENDING→... |

## 业务规则

> 从代码逻辑中提取的隐性业务规则（Service 层的条件判断往往是金矿）

| 规则编号 | 规则描述 | 代码位置 |
|---------|---------|---------|
| BR-001 | 订单金额超过 5000 元时需要人工审核 | OrderService.java:142 |

## 领域事件

> 系统中发布/订阅的事件，或状态变更的触发点

| 事件名 | 触发时机 | 影响模块 |
|--------|---------|---------|
| OrderCreated | 订单创建成功 | inventory, notification |
```

#### 2.2 业务流程识别

对用户确认的核心模块，阅读 Service 层/业务逻辑层的核心方法，识别：
- 主要业务流程（购买流程、审批流程、结算流程等）
- 流程中的关键决策点（if/else 分支 = 业务规则）
- 跨模块交互（一个 Service 调用另一个 Service）

将识别到的主要流程以**步骤列表**形式记录到术语表文档的「业务流程」章节。

---

### 阶段三：编码规范提取

> **目标**：将项目已有的编码风格固化为明确规范，避免 dev-agent 引入不一致风格。

#### 3.1 命名约定分析

读取 10~20 个典型的源码文件，分析：

| 层级 | 观察内容 | 示例 |
|------|---------|------|
| 类/文件命名 | PascalCase? 有无后缀规范？ | UserService、UserRepo、UserDTO |
| 方法命名 | camelCase? 动词前缀习惯？ | findById、createUser、handleEvent |
| 变量命名 | 驼峰/下划线？缩写习惯？ | userId vs user_id vs uid |
| 常量命名 | UPPER_SNAKE？ | MAX_RETRY_COUNT |
| 包/目录命名 | 复数？功能名？ | controllers/ vs controller/ |
| 测试文件命名 | 前缀/后缀规范？ | UserServiceTest vs test_user_service |

#### 3.2 代码结构规范分析

分析项目典型文件，提取：
- 文件头部习惯（版权声明、导入顺序）
- 方法顺序约定（public 先还是 private 先）
- 错误处理风格（异常类 vs 错误码 vs Result 类型）
- 日志记录风格（日志级别使用习惯、是否有结构化日志）
- 注释风格（是否有 JSDoc/JavaDoc？何时写注释？）

#### 3.3 架构约定分析

- 分层命名（Controller→Service→Repository 还是其他？）
- 依赖注入方式（构造器注入 vs 字段注入）
- 接口命名（IUserService vs UserService interface vs UserRepository）
- 事务管理方式（注解 vs 编程式）
- 配置管理方式（环境变量 vs 配置文件 vs 配置中心）

**输出文件**：`docs/knowledges/standards/{tech}-coding-standards.md`

```markdown
## Meta
- **类型**：编码规范
- **适用场景**：dev-agent 编写代码时严格遵循
- **关键词**：{技术栈}，命名规范，代码风格，编码约定
- **创建时间**：{今天日期}
- **来源功能**：brownfield-onboard

---

# {技术栈} 编码规范

> **本规范从现有代码中提取，代表项目的实际约定。**
> 新代码必须遵循这些约定，保持风格一致。

## 命名约定

| 类型 | 规范 | 示例 |
|------|------|------|
| 类/接口 | PascalCase + 功能后缀 | UserService, OrderRepository |
| 方法 | camelCase，动词开头 | findById(), createOrder() |
| 变量 | camelCase | userId, orderList |
| 常量 | UPPER_SNAKE_CASE | MAX_PAGE_SIZE |
| 包/目录 | lowercase，复数形式 | services/, repositories/ |

## 文件结构约定

{描述文件内部组织顺序，例如：imports → constants → class → exports}

## 错误处理约定

{描述项目的错误处理模式}

## 日志约定

{描述日志级别使用规则和格式}

## 禁止清单

> 这些写法在项目中不被接受，避免引入

- ❌ 不使用字段注入（@Autowired on field），改用构造器注入
- ❌ 不在 Service 层直接操作 HttpRequest，应在 Controller 层提取
- ❌ {其他从代码观察到的反模式}
```

---

### 阶段四：设计规范提取

> **目标**：记录项目的架构模式和设计决策，为 arch-agent 提供上下文。

#### 4.1 架构模式识别

阅读 `docs/architecture.md` 和实际代码，确认/补充：
- 实际使用的架构模式（MVC / 六边形 / 分层 / CQRS 等）
- 与框架标准分层的映射关系（如果 `docs/architecture.md §分层映射表` 尚未填写）

#### 4.2 集成模式识别

扫描代码中的外部集成：
- HTTP 客户端调用（RestTemplate、axios、requests 等）
- 消息队列使用（Kafka、RabbitMQ、Redis Pub/Sub）
- 缓存策略（Redis、本地缓存、缓存键命名规则）
- 文件存储（本地 / S3 / OSS）
- 第三方 SDK 使用（支付、短信、地图等）

#### 4.3 数据访问模式识别

- ORM 使用方式（Repository 模式 / Active Record / 原生 SQL）
- 分页模式（Cursor / Offset / Keyset）
- 软删除策略（is_deleted 字段 / deleted_at / 独立归档表）
- 多租户策略（如果适用）

**输出文件**：`docs/knowledges/architecture/001-brownfield-patterns.md`

```markdown
## Meta
- **类型**：架构决策记录
- **适用场景**：技术方案设计时，了解项目已采用的模式和约束
- **关键词**：架构模式，集成，数据访问，{技术栈}
- **创建时间**：{今天日期}
- **来源功能**：brownfield-onboard

---

# 棕地项目架构模式记录

## 整体架构

- **架构风格**：{MVC / 六边形 / 分层 / 微服务}
- **分层结构**：{层名1} → {层名2} → {层名3} → {层名4}

## 集成模式清单

| 集成类型 | 实现方式 | 关键文件 | 注意事项 |
|---------|---------|---------|---------|
| 外部 HTTP | {client 名} | {路径} | {超时/重试配置} |
| 消息队列 | {MQ 名} | {路径} | {消费者组} |
| 缓存 | {缓存类型} | {路径} | {TTL 约定} |

## 数据访问模式

- **ORM**：{框架名}，使用 {Repository 模式 / Active Record}
- **分页**：使用 {Offset / Cursor} 分页，默认 PageSize = {N}
- **软删除**：{有/无，字段名}

## 已知技术债（设计层面）

| 编号 | 描述 | 影响范围 | 建议改善时机 |
|------|------|---------|------------|
| TD-001 | {技术债描述} | {影响模块} | {触发条件} |
```

---

### 阶段五：规格文档补充（Spec 补充）

> **目标**：为最核心的已有功能创建轻量级规格文档，作为追溯起点。

#### 5.1 核心功能识别

综合以下信号识别最需要补充规格的功能：
1. **路由密度**：控制器中方法最多的模块（通常是核心业务）
2. **依赖中心**：被最多其他模块调用的 Service
3. **代码复杂度**：方法行数最多、分支最多的文件
4. **用户价值**：结合用户之前提供的信息（如有）

与用户确认：
> 「根据分析，以下功能最适合补充规格文档（按优先级排序）：
> 1. {功能A} — 被 {N} 个模块依赖，是核心业务流程
> 2. {功能B} — API 最多，{N} 个端点
> 3. {功能C} — 代码最复杂，有 {N} 个业务分支
> 请选择希望补充规格的功能（可多选），或告知其他优先项。」

#### 5.2 为每个选定功能创建轻量级规格

对每个功能，在 `docs/specs/{feature-name}/` 创建：

**tech.md（必须）**：

```markdown
## Meta

| 字段 | 值 |
|------|-----|
| status | legacy-documented |
| traces_to | upstream: (遗留代码，无 requirement.md); downstream: (无) |
| created | {今天日期} |
| source | brownfield-onboard（从现有代码反向提取）|
| last_updated | {今天日期} |

---

# {功能名} 技术文档

> **注意**：本文档从现有代码反向提取，不代表最初的设计意图。
> 如需修改此功能，应先创建正式的 requirement.md 和 product.md。

## 功能职责

{1~3 句话描述该功能的核心职责}

## API 接口清单

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| GET | /api/v1/... | ... | JWT |

## 核心数据模型

```json
{
  "field1": "type — 说明",
  "field2": "type — 说明"
}
```

## 主要业务规则

> 从 Service 层代码中提取的隐性规则

- BR-001：{规则描述}（来源：{类名}:{行号}）

## 已知约束与技术债

- {限制或技术债描述}

## 关联模块

| 模块 | 关系 | 说明 |
|------|------|------|
| {模块名} | 依赖 / 被依赖 | {说明} |
```

**（可选）requirement.md（极简版）**：

当功能具有明确用户价值且后续可能迭代时，补充极简需求文档：

```markdown
## Meta

| 字段 | 值 |
|------|-----|
| status | legacy-inferred |
| traces_to | upstream: (遗留需求，无正式文件); downstream: tech: docs/specs/{feature}/tech.md |
| created | {今天日期} |

---

# {功能名} 需求（遗留推断版）

> 本文档根据现有代码功能反向推断，不是原始需求文档。

## 功能描述

{从代码推断的功能目标}

## 主要用户场景

| 场景 | 用户行为 | 系统响应 |
|------|---------|---------|
| {场景1} | ... | ... |
```

#### 5.3 更新功能索引

将补充规格的功能登记到 `docs/specs/index.md`：

```markdown
| {功能名} | legacy-documented | {简短描述} | brownfield-onboard |
```

---

### 阶段六：更新知识索引与 Agent 上下文

#### 6.1 更新知识库索引

将本次创建的所有知识文件追加到 `docs/knowledges/index.md` 的索引表：

| 类型 | 文件路径 | 适用场景 | 关键词 |
|------|---------|---------|--------|
| 业务领域知识 | `domain/{domain}-glossary.md` | 编写需求/技术文档时统一术语 | {核心术语} |
| 编码规范 | `standards/{tech}-coding-standards.md` | dev-agent 编写代码时遵循 | 编码规范,命名,风格 |
| 架构决策 | `architecture/001-brownfield-patterns.md` | 技术方案设计时了解现有模式 | 架构,集成,数据访问 |

#### 6.2 更新 Agent 注入区

将提取到的关键信息写入各 Agent 的 `DYNAMIC_INJECT` 区：

**dev-agent.md 注入区追加**：
```markdown
- **业务术语**：参见 docs/knowledges/domain/{domain}-glossary.md（编写代码时统一使用术语表中的命名）
- **编码规范**：参见 docs/knowledges/standards/{tech}-coding-standards.md（必须遵循禁止清单）
```

**arch-agent.md 注入区追加**：
```markdown
- **现有架构模式**：参见 docs/knowledges/architecture/001-brownfield-patterns.md
- **已知技术债**：设计新方案时避免加重已记录的技术债
```

#### 6.3 更新 workspace/memory.md

在 `§C 活跃约束` 区域追加：
```markdown
- **棕地知识已提取（{今天日期}）**：已为 {N} 个核心模块提取业务术语/编码规范/设计规范，相关 agent 已配置引用
```

---

### 阶段七：输出总结报告

向用户输出总结：

```markdown
## /brownfield-onboard 完成

### 知识库新增

| 文件 | 内容摘要 | 关键发现 |
|------|---------|---------|
| `docs/knowledges/domain/{domain}-glossary.md` | {N} 个业务实体，{M} 条业务规则 | {最重要的发现} |
| `docs/knowledges/standards/{tech}-coding-standards.md` | {N} 条命名约定，{M} 条禁止规则 | {最重要的发现} |
| `docs/knowledges/architecture/001-brownfield-patterns.md` | {架构风格}，{N} 种集成模式，{M} 项技术债 | {最重要的发现} |

### 规格文档新增

| 功能 | 文档类型 | 路径 |
|------|---------|------|
| {功能A} | tech.md | docs/specs/{feature-a}/ |
| {功能B} | tech.md + requirement.md | docs/specs/{feature-b}/ |

### 需要人工确认的内容

> 以下内容是从代码推断的，可能不准确，请人工核实：

1. **术语定义**：{不确定的术语} — 推断含义为 {X}，是否正确？
2. **业务规则**：{规则描述} — 是否是刻意设计还是历史遗留？
3. **技术债**：{TD编号} — 是否已有改善计划？

### 下一步建议

1. 核实上方「需要人工确认」的内容，直接修改对应文档
2. 新功能开发时，dev-agent 将自动参考提取的编码规范和术语表
3. 如需对旧功能进行较大修改，建议先用 `/bug-fix` 或 `/new-feature` 创建正式流程
4. 定期使用 `/health-check` 检查知识库是否与代码漂移
```

---

## 注意事项

- 本 skill **不会修改任何业务代码**，只创建/更新知识文档
- 提取的知识是**从代码推断**的，可能存在误差，需要人工确认
- 对于超大型项目（>100 个模块），应让用户先指定重点分析范围，避免分析过宽
- 如果项目尚未运行 `/init-project`，提示用户先完成框架初始化
- 本 skill 可以重复运行（如引入新模块后），会追加而非覆盖已有知识
