# {功能名称} — 测试用例
<!-- template-version: 1 -->

## Meta
- status: draft | reviewed | executed
- created: {YYYY-MM-DD}
- author: qa-agent
- traces_to:
  - upstream:
    - test-plan: docs/specs/{feature}/test-plan.md
    - requirement: docs/specs/{feature}/requirement.md
  - downstream: （测试执行后更新覆盖矩阵）

---

## 测试用例

| 用例ID | 模块 | 前置条件 | 操作步骤 | 预期结果 | 优先级 | 状态 |
|--------|------|---------|---------|---------|--------|------|
| TC-001 | {模块名} | {前置条件描述} | 1. {步骤1} 2. {步骤2} | {预期结果} | P0 | pending |
| TC-002 | | | | | P1 | pending |

### 优先级说明
- **P0**: 核心功能，阻塞发布，不可跳过
- **P1**: 重要功能，应修复，可记录后继续
- **P2**: 边缘场景，可延后处理

### 状态说明
- **pending**: 待执行
- **pass**: 通过
- **fail**: 失败（需记录错误信息）
- **skip**: 跳过（需记录原因，P0 用例不可跳过）
- **blocked**: 被阻塞（需记录阻塞原因）

---

## 覆盖矩阵

> 测试执行后，汇总覆盖情况。

| AC 编号 | AC 描述 | 关联用例 | 覆盖状态 |
|---------|---------|---------|---------|
| AC-1 | {验收标准描述} | TC-001, TC-003 | covered / not-covered |

---

## Feedback Log
