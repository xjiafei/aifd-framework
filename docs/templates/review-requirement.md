---
feature: {feature-name}
stage: P1-requirement
created: {日期}
traces_to:
  upstream: (无)
  downstream: docs/specs/{feature}/review-product.md
---

# 需求评审记录

## 评审信息

- **评审轮次**：第 {N} 轮
- **评审日期**：{日期}
- **评审结论**：APPROVED / CHANGES_REQUESTED / REJECTED

---

## pm-agent 自检结论

**结论**：PASS / FAIL

**未满足的质量标准**（如有）：
- CHK-{N}：{问题描述}

---

## 各角色评审意见

### qa-agent（AC 可测试性）

**结论**：PASS / WARN / FAIL

| 检查项 | 结果 | 意见 |
|--------|------|------|
| AC 可测量性（每条 AC 可转化为测试断言） | PASS/FAIL | |
| 边缘场景覆盖（空输入/并发/权限/异常） | PASS/FAIL | |
| 用户故事独立性（US 间无隐性依赖） | PASS/FAIL | |

**具体意见**：
- {意见}

### arch-agent（技术可行性 / 数据域完整性）

**结论**：PASS / WARN / FAIL

| 检查项 | 结果 | 意见 |
|--------|------|------|
| 数据域定义完整（类型/长度/约束/默认值） | PASS/FAIL | |
| 外部依赖已声明 | PASS/FAIL | |
| 技术可行性无明显风险 | PASS/FAIL | |

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
