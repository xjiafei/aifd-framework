---
feature: {feature-name}
stage: P2-product
created: {日期}
traces_to:
  upstream: docs/specs/{feature}/review-requirement.md
  downstream: docs/specs/{feature}/review-tech.md
---

# 产品设计评审记录

## 评审信息

- **评审轮次**：第 {N} 轮
- **评审日期**：{日期}
- **评审结论**：APPROVED / CHANGES_REQUESTED / REJECTED

---

## pm-agent 自检结论

**结论**：PASS / FAIL

**未满足项**（如有）：
- {问题描述}

---

## 各角色评审意见

### arch-agent（技术可行性 / 技术约束对齐）

**结论**：FEASIBLE / CONCERNS / INFEASIBLE

| 检查项 | 结果 | 意见 |
|--------|------|------|
| 技术可行性（可实现性无明显风险） | FEASIBLE/CONCERNS | |
| 与现有架构一致性 | PASS/FAIL | |
| 性能/扩展性风险 | 无/低/中/高 | |
| 信息架构实体关系完整 | PASS/FAIL | |

**具体意见**：
- {意见}

### qa-agent（端到端可测试性）

**结论**：TESTABLE / CONCERNS

| 检查项 | 结果 | 意见 |
|--------|------|------|
| 用户流程端到端可测试 | PASS/FAIL | |
| 无死胡同（所有状态有出口） | PASS/FAIL | |
| 错误状态和空状态有设计 | PASS/FAIL | |
| 与 requirement.md AC 完全对应 | PASS/FAIL | |

**具体意见**：
- {意见}

### 人工评审意见

- {意见1}
- {意见2}

---

## 修改记录

| 轮次 | 修改内容摘要 | 修改后结论 |
|------|------------|----------|
| 第1轮 | {修改摘要} | APPROVED |
