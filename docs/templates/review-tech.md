---
feature: {feature-name}
stage: P3-tech
created: {日期}
traces_to:
  upstream: docs/specs/{feature}/review-product.md
  downstream: docs/specs/{feature}/review-log.md
---

# 技术设计评审记录

## 评审信息

- **评审轮次**：第 {N} 轮
- **评审日期**：{日期}
- **评审结论**：APPROVED / CHANGES_REQUESTED / REJECTED

---

## precheck-agent 自动预检

**预检结论**：PASS / WARN / FAIL

| 文档 | 结论 | 问题 |
|------|------|------|
| tech.md | PASS/WARN/FAIL | {问题列表，无则填"无"} |
| exec-plan.md | PASS/WARN/FAIL | |
| test-plan.md | PASS/WARN/FAIL | |
| test-cases.md | PASS/WARN/FAIL | |

---

## 各角色评审意见

### arch-agent（技术自评）

**结论**：PASS / CONCERNS

| 检查项 | 结果 | 意见 |
|--------|------|------|
| 分层合规（无反向依赖/循环依赖） | PASS/FAIL | |
| API 可实现性（接口定义足够清晰） | PASS/FAIL | |
| 里程碑粒度合理 | PASS/FAIL | |
| 构建/验证命令已明确 | PASS/FAIL | |

**风险点**：
- {已知技术风险或不确定项}

### pm-agent（需求一致性）

**结论**：CONSISTENT / GAPS_FOUND

| 需求项（FR/US） | 是否覆盖 | 说明 |
|---------------|---------|------|
| FR-001 {描述} | ✅/❌ | |
| FR-002 {描述} | ✅/❌ | |

**差距说明**（如有）：
- {未覆盖的需求项及建议}

### qa-agent（可测性评估）

**结论**：TESTABLE / CONCERNS

| 检查项 | 结果 | 意见 |
|--------|------|------|
| 每个 AC 有对应测试用例 | PASS/FAIL | |
| P0 用例覆盖核心路径 | PASS/FAIL | |
| 测试步骤可直接执行（前置条件明确） | PASS/FAIL | |
| 边缘场景有测试用例 | PASS/FAIL | |

**难以测试的点**（如有）：
- {说明}

### dev-agent（API 可实现性 / 里程碑粒度）

**结论**：FEASIBLE / CONCERNS

- {实现可行性评估}
- {里程碑粒度建议}

### 人工评审意见

- {意见1}
- {意见2}

---

## 跨工件一致性检查结果

**FR → tech.md → exec-plan 三角检查**：

| FR-### | tech.md 章节 | exec-plan 里程碑 | 状态 |
|--------|-------------|----------------|------|
| FR-001 | §{N} | M{N} | ✅/❌ |

---

## 修改记录

| 轮次 | 修改内容摘要 | 修改后结论 |
|------|------------|----------|
| 第1轮 | {修改摘要} | APPROVED |
