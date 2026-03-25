---
name: health-check
description: "当需要检查框架健康状况、计算质量诊断指标、发现潜在的文档/架构问题时使用。"
---

# /health-check — 框架健康检查

> 自动收集 docs/quality.md 中定义的诊断层和运营层指标，产出健康报告。

---

## 执行流程

### 第一步：收集诊断层指标

#### 1.1 traces_to 有效性检查

扫描所有 `docs/specs/` 下的文档，验证每个 `traces_to` 字段：
- 使用 `Glob` 找到所有 `docs/specs/**/*.md` 文件
- 对每个文件，读取 `traces_to` 字段的值
- 使用 `Read` 验证每个引用路径是否存在
- 记录：**失效链接数**

#### 1.2 Stale Docs 检测

Stale doc 定义：文档的 `last_updated` 字段超过 30 天，且对应的代码文件在此期间有修改记录（如果可以通过 git 获取）。

简化判断方式（无 git 时）：
- 检查 `docs/plans/completed/` 中是否有对应的执行计划
- 检查该执行计划完成后，相关代码路径的 `tech.md` 是否更新
- 记录：**疑似 Stale 文档数**

#### 1.3 stage-status.json 一致性检查

读取 `workspace/stage-status.json`：
- 是否为 v2 多功能格式（`_schema: v2-multi-feature`）
- 是否有 `status=failed` 的功能（需要人工介入）
- 是否有 `status=waiting_approval` 且时间超过 24 小时的功能（可能被遗忘）
- 记录：**状态异常数**

#### 1.4 Code Review Log 未解决问题统计

读取 `workspace/code-review-log.md`：
- 统计 `status: open` 的 CRITICAL 和 HIGH 级别问题数
- 统计累计 open 问题数
- 记录：**未解决问题数（按级别）**

#### 1.5 Framework Health 记录检查

读取 `workspace/framework-health.md`：
- 查看上次框架自检日期
- 已完成功能数 vs 自检频率（每 3 个功能一次）
- 记录：**是否逾期自检**

### 第二步：收集运营层指标

读取 `docs/specs/` 下所有需求文档，统计：

#### 2.1 Plan Coverage（执行计划覆盖率）

```
Plan Coverage = 有对应 exec-plan 的 FR 数 / 总 FR 数
```

扫描 `docs/specs/*/requirement.md` 中的 FR-### 条目数，与 `docs/plans/` 中的里程碑数对比。

#### 2.2 Feature Completion Rate

```
Feature Completion Rate = completed 功能数 / 总功能数
```

从 `workspace/stage-status.json` 的 `features` 中统计。

#### 2.3 孤儿文件检测

扫描 `docs/specs/` 下的所有子目录，对比 `docs/specs/index.md` 中已登记的功能列表：
- 在 specs/ 有目录但 index.md 中没有记录 → **孤儿目录**（可能是未完成的功能或被遗忘的草稿）
- 记录：**孤儿目录数及路径**

#### 2.4 量化指标趋势（来自 metrics 字段）

从 `workspace/stage-status.json` 的 `features` 和 `archived` 中，统计近期已完成功能的：
```
平均 Gate 失败次数 = sum(metrics.gateFailCount) / 已完成功能数
平均 P4 循环轮次 = sum(metrics.loopRoundTotal) / 已完成功能数
CR CRITICAL 总计 = sum(metrics.crCriticalCount)
```
**趋势说明**：指标随时间下降 = 框架在改进；持续升高 = 需要检查流程问题。

#### 2.5 completed 功能归档

检查 `features` 中 `status=completed` 且 `completedAt` 超过 30 天的功能：
- 若存在 → 将其摘要信息移入 `archived` 数组，从 `features` 对象中删除
- 更新 `workspace/stage-status.json`

### 第三步：生成健康报告

输出到 `workspace/framework-health.md`（追加，不覆盖历史记录）：

```markdown
## 健康检查报告 — {日期}

### 诊断层指标

| 指标 | 当前值 | 告警阈值 | 状态 |
|------|--------|---------|------|
| traces_to 失效链接数 | {N} | > 0 告警 | ✅/⚠️/❌ |
| 疑似 Stale 文档数 | {N} | > 2 触发 GC | ✅/⚠️/❌ |
| stage-status 异常数 | {N} | > 0 告警 | ✅/⚠️/❌ |
| CR Log 未解决 CRITICAL | {N} | > 0 告警 | ✅/⚠️/❌ |
| CR Log 未解决 HIGH | {N} | > 3 告警 | ✅/⚠️/❌ |
| 孤儿 specs 目录数 | {N} | > 0 告警 | ✅/⚠️/❌ |
| 框架自检逾期 | 是/否 | — | ✅/⚠️ |

### 运营层指标

| 指标 | 当前值 |
|------|--------|
| Plan Coverage | {N}% |
| Feature Completion Rate | {N}/{M} |
| 平均 Gate 失败次数/功能 | {N} |
| 平均 P4 循环轮次/功能 | {N} |
| CR CRITICAL 总计（近期） | {N} |

### 趋势分析

{与上次报告对比，指标改善/恶化的说明}

### completed 功能已归档

{本次归档的功能列表，如无则注明"无"}

### 需要立即关注的问题

{仅列出状态为 ❌ 的指标和具体问题描述，孤儿目录需列出路径}

### 建议的下一步行动

{基于指标数据给出 1-3 条具体建议}
```

### 第四步：如果发现严重问题

- **traces_to 失效链接 > 3**：列出所有失效链接，建议立即修复
- **Stale 文档 > 2**：列出疑似 Stale 的文档，建议下次 GC 时同步
- **CR Log CRITICAL 未解决 > 0**：列出具体问题，建议本次解决
- **框架自检逾期**：提示执行框架自检（框架流程是否有冗余步骤、模板是否需更新）

---

## 输出

健康报告追加到 `workspace/framework-health.md`。
如有需要立即处理的 CRITICAL 问题，同时通知编排者。
