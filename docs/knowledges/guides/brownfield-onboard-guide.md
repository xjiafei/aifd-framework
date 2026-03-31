## Meta
- **类型**：操作指南
- **适用场景**：运行 `/brownfield-onboard` 后，了解产出文件的维护规范和使用方式
- **关键词**：棕地，遗留系统，知识提取，术语表，编码规范，设计规范，spec补充
- **创建时间**：2026-03-30
- **来源功能**：brownfield-onboard

---

# 棕地项目知识化产出维护指南

## 产出文件一览

`/brownfield-onboard` 会在以下位置创建文件：

| 文件路径 | 类型 | 维护频率 |
|---------|------|---------|
| `docs/knowledges/domain/{domain}-glossary.md` | 业务术语表 + 业务规则 | 业务扩展时追加 |
| `docs/knowledges/standards/{tech}-coding-standards.md` | 编码规范 + 禁止清单 | 发现新约定时更新 |
| `docs/knowledges/architecture/001-brownfield-patterns.md` | 架构模式 + 技术债清单 | 架构调整时更新 |
| `docs/specs/{feature}/tech.md`（legacy-documented） | 遗留功能接口文档 | 功能迭代时同步更新 |

---

## 术语表维护规范

### 何时更新

- 发现新的业务实体（新加字段、新枚举值）时追加
- 业务规则发生变化时更新对应条目并标注变更日期
- 旧术语被废弃时注明 `[废弃: 改用 {新术语}]`，保留条目不删除

### 如何引用

在 requirement.md / tech.md 中引用术语表中的术语时，使用代码名（与代码一致），并在首次出现时加注括号说明，例如：
> "当 Order（订单）状态变为 CONFIRMED 时..."

---

## 编码规范维护规范

### 何时更新

- 团队决定改变某项约定时，更新规范并添加"变更日志"条目
- 发现新的反模式时添加到"禁止清单"
- 引入新技术栈时创建对应的规范文件（`{tech}-coding-standards.md`）

### dev-agent 使用规则

dev-agent 在编写代码时**必须检查**：
1. 新代码是否遵循命名约定
2. 新代码是否触犯了禁止清单
3. 错误处理方式是否与项目约定一致

---

## 架构模式文件维护规范

### 技术债追踪

`001-brownfield-patterns.md` 中的技术债表格应与实际代码同步：
- 每次 GC 循环时检查技术债是否已改善，更新"影响范围"和"建议时机"列
- 当技术债通过重构消除时，标注为 `[已解决: {日期}]`，保留历史记录

### 新增集成模式

引入新的外部依赖（新消息队列、新缓存、新第三方 API）时，追加到"集成模式清单"表格。

---

## 遗留规格文档（legacy-documented）说明

`/brownfield-onboard` 创建的 tech.md 带有 `status: legacy-documented` 标记，含义：

- **不等于完整规格**：缺少 requirement.md（需求）和 product.md（产品设计）
- **可直接作为追溯起点**：新功能的 traces_to 可以引用这些文件
- **修改时需升级**：对 legacy-documented 功能进行较大修改时，应先补充 requirement.md，走正式流程

### 升级路径

| 变更幅度 | 处理方式 |
|---------|---------|
| 小修改（接口不变） | 直接更新 tech.md，status 保持 legacy-documented |
| 中等修改（接口有变）| 补充 requirement.md，tech.md 状态改为 in-revision |
| 大改 / 重设计 | 走完整 `/new-feature` 流程 |

---

## 重新运行 `/brownfield-onboard`

在以下场景可重新运行（会追加不覆盖）：
- 项目引入了新的主要模块
- 团队新成员加入，需要更新术语表
- 定期（每半年）进行知识库刷新

重新运行时，skill 会检测已有文件并采用追加模式，不会覆盖人工修订的内容。
